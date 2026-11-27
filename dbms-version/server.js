require("dotenv").config();
const express = require("express");
const mysql = require("mysql2/promise");
const path = require("path");
const app = express();
app.use(express.json());
app.use(express.static(path.join(__dirname, "public")));

const pool = mysql.createPool({
  host: process.env.DB_HOST || "localhost",
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD || "",
  database: process.env.DB_NAME || "event_resource_db",
  waitForConnections: true, connectionLimit: 10, dateStrings: true
});
const route = fn => (req,res,next) => Promise.resolve(fn(req,res,next)).catch(next);

app.get("/api/health", route(async(req,res)=>{
  await pool.query("SELECT 1");
  res.json({status:"ok",database:"connected"});
}));
app.get("/api/resources", route(async(req,res)=>{
  const [rows]=await pool.query("SELECT resource_id,resource_name FROM resources ORDER BY resource_name");
  res.json(rows);
}));
app.get("/api/events", route(async(req,res)=>{
  const like="%"+String(req.query.search||"").trim()+"%";
  const [rows]=await pool.execute(`SELECT event_id AS id,event_name AS name,
    DATE_FORMAT(event_date,'%Y-%m-%d') AS date,
    TIME_FORMAT(start_time,'%H:%i') AS start,TIME_FORMAT(end_time,'%H:%i') AS end,
    resource_name AS resource,COALESCE(organizer_name,'') AS organizer
    FROM event_details
    WHERE event_name LIKE ? OR resource_name LIKE ? OR COALESCE(organizer_name,'') LIKE ?
    ORDER BY event_date,start_time`,[like,like,like]);
  res.json(rows);
}));
app.post("/api/events", route(async(req,res)=>{
  const {name,date,start,end,resource,organizer=""}=req.body;
  if(![name,date,start,end,resource].every(v=>String(v||"").trim()))
    return res.status(400).json({message:"Please fill all required fields."});
  if(!/^\d{4}-\d{2}-\d{2}$/.test(date)||!/^\d{2}:\d{2}$/.test(start)||
     !/^\d{2}:\d{2}$/.test(end)||start>=end)
    return res.status(400).json({message:"Invalid date or time range. End time must be later than start time."});

  const c=await pool.getConnection();
  let lockName;
  try {
    await c.beginTransaction();
    lockName="event_"+String(resource).slice(0,40)+"_"+date;
    const [[lock]]=await c.query("SELECT GET_LOCK(?,5) AS acquired",[lockName]);
    if(lock.acquired!==1){await c.rollback();return res.status(409).json({message:"Resource is busy. Please try again."});}
    const [rr]=await c.execute("SELECT resource_id FROM resources WHERE resource_name=?",[resource]);
    if(!rr.length){await c.rollback();return res.status(400).json({message:"Invalid resource selected."});}
    const [conflicts]=await c.execute(`SELECT event_id,event_name,
      TIME_FORMAT(start_time,'%H:%i') AS start,TIME_FORMAT(end_time,'%H:%i') AS end
      FROM events WHERE event_date=? AND resource_id=? AND start_time<? AND end_time>?`,
      [date,rr[0].resource_id,end,start]);
    if(conflicts.length){await c.rollback();return res.status(409).json({
      message:"Conflict detected! This resource is already booked during that time.",conflicts
    });}
    let organizerId=null;
    if(String(organizer).trim()){
      const [o]=await c.execute(`INSERT INTO organizers(organizer_name) VALUES(?)
        ON DUPLICATE KEY UPDATE organizer_id=LAST_INSERT_ID(organizer_id)`,[String(organizer).trim()]);
      organizerId=o.insertId;
    }
    const [result]=await c.execute(`INSERT INTO events
      (event_name,event_date,start_time,end_time,resource_id,organizer_id) VALUES(?,?,?,?,?,?)`,
      [String(name).trim(),date,start,end,rr[0].resource_id,organizerId]);
    await c.commit();
    res.status(201).json({message:"Event saved successfully. No conflict found.",id:result.insertId});
  } catch(e){await c.rollback();throw e;}
  finally{
    if(lockName){try{await c.query("SELECT RELEASE_LOCK(?)",[lockName]);}catch(_){}}
    c.release();
  }
}));
app.delete("/api/events/:id",route(async(req,res)=>{
  const id=Number(req.params.id);
  if(!Number.isInteger(id)||id<1)return res.status(400).json({message:"Invalid event ID."});
  const [r]=await pool.execute("DELETE FROM events WHERE event_id=?",[id]);
  if(!r.affectedRows)return res.status(404).json({message:"Event not found."});
  res.json({message:"Event deleted successfully."});
}));
app.get("/api/stats",route(async(req,res)=>{
  const [[s]]=await pool.query("SELECT COUNT(*) totalEvents,COUNT(DISTINCT resource_id) usedResources,COUNT(DISTINCT event_date) eventDates FROM events");
  res.json(s);
}));
app.use((err,req,res,next)=>{
  console.error(err);
  res.status(500).json({message:"Server/database error. Check MySQL connection and server console."});
});
const port=Number(process.env.PORT||3000);
app.listen(port,()=>console.log("Server running at http://localhost:"+port));
