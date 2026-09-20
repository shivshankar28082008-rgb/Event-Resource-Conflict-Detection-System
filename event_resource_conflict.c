#include <stdio.h>
#include <string.h>

#define MAX_EVENTS 100

struct Event {
    char name[100];
    char date[20];       /* YYYY-MM-DD */
    char start[6];       /* HH:MM */
    char end[6];         /* HH:MM */
    char resource[50];
    char organizer[100];
};

struct Event events[MAX_EVENTS];
int eventCount = 0;

void clearInputBuffer(void) {
    int c;
    while ((c = getchar()) != '\n' && c != EOF) {}
}

void readLine(char *text, int size) {
    fgets(text, size, stdin);
    text[strcspn(text, "\n")] = '\0';
}

int timeToMinutes(const char *time) {
    int h, m;
    if (sscanf(time, "%d:%d", &h, &m) != 2) return -1;
    if (h < 0 || h > 23 || m < 0 || m > 59) return -1;
    return h * 60 + m;
}

int overlaps(struct Event a, struct Event b) {
    int aStart = timeToMinutes(a.start);
    int aEnd = timeToMinutes(a.end);
    int bStart = timeToMinutes(b.start);
    int bEnd = timeToMinutes(b.end);

    return aStart < bEnd && bStart < aEnd;
}

void showInstructions(void) {
    printf("\n==============================================\n");
    printf("      EVENT RESOURCE CONFLICT DETECTION\n");
    printf("==============================================\n");
    printf("1. Add event name, date and time.\n");
    printf("2. Select a room/resource.\n");
    printf("3. The system checks for overlapping events.\n");
    printf("4. Same resource + same date + overlapping time\n");
    printf("   is reported as a conflict.\n");
    printf("5. View all scheduled events.\n");
    printf("==============================================\n");
}

void addEvent(void) {
    if (eventCount >= MAX_EVENTS) {
        printf("\nEvent limit reached.\n");
        return;
    }

    struct Event e;

    clearInputBuffer();

    printf("\nEvent Name: ");
    readLine(e.name, sizeof(e.name));

    printf("Date (YYYY-MM-DD): ");
    readLine(e.date, sizeof(e.date));

    printf("Start Time (HH:MM): ");
    readLine(e.start, sizeof(e.start));

    printf("End Time (HH:MM): ");
    readLine(e.end, sizeof(e.end));

    printf("Resource/Room: ");
    readLine(e.resource, sizeof(e.resource));

    printf("Organizer: ");
    readLine(e.organizer, sizeof(e.organizer));

    int start = timeToMinutes(e.start);
    int end = timeToMinutes(e.end);

    if (start < 0 || end < 0 || start >= end) {
        printf("\nInvalid time range! Please enter valid HH:MM times.\n");
        return;
    }

    int conflictFound = 0;

    for (int i = 0; i < eventCount; i++) {
        if (strcmp(events[i].date, e.date) == 0 &&
            strcmp(events[i].resource, e.resource) == 0 &&
            overlaps(events[i], e)) {
            printf("\n⚠️ CONFLICT DETECTED!\n");
            printf("Existing Event : %s (%s-%s)\n",
                   events[i].name, events[i].start, events[i].end);
            printf("New Event      : %s (%s-%s)\n",
                   e.name, e.start, e.end);
            conflictFound = 1;
        }
    }

    events[eventCount++] = e;

    if (!conflictFound)
        printf("\n✅ Event added successfully. No conflict found.\n");
    else
        printf("\n⚠️ Event was added, but it overlaps an existing resource booking.\n");
}

void showEvents(void) {
    printf("\n==============================================\n");
    printf("                 EVENT LIST\n");
    printf("==============================================\n");

    if (eventCount == 0) {
        printf("No events scheduled yet.\n");
        return;
    }

    for (int i = 0; i < eventCount; i++) {
        printf("\nEvent %d\n", i + 1);
        printf("----------------------------------------------\n");
        printf("Name      : %s\n", events[i].name);
        printf("Date      : %s\n", events[i].date);
        printf("Time      : %s - %s\n", events[i].start, events[i].end);
        printf("Resource  : %s\n", events[i].resource);
        printf("Organizer : %s\n", events[i].organizer);
    }
}

int main(void) {
    int choice;

    while (1) {
        printf("\n\n==============================================\n");
        printf("      EVENT RESOURCE CONFLICT DETECTION\n");
        printf("==============================================\n");
        printf("1. Add Event\n");
        printf("2. View Event List\n");
        printf("3. Instructions\n");
        printf("4. Exit\n");
        printf("==============================================\n");
        printf("Enter your choice: ");

        if (scanf("%d", &choice) != 1) {
            clearInputBuffer();
            printf("Invalid input. Please enter a number.\n");
            continue;
        }

        switch (choice) {
            case 1:
                addEvent();
                break;
            case 2:
                showEvents();
                break;
            case 3:
                showInstructions();
                break;
            case 4:
                printf("\nThank you for using the system!\n");
                return 0;
            default:
                printf("\nInvalid choice! Please select 1-4.\n");
        }
    }
}
