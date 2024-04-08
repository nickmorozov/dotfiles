#!/usr/bin/env node

const { exec } = require('child_process');
const fs = require('fs');

exec('echo "" | shortcuts run Syncer', (error, stdout, stderr) => {
  if (error) {
    console.log(`error: ${error.message}`);
    return;
  }

  if (stderr) {
    console.log(`stderr: ${stderr}`);
    return;
  }

  const data = JSON.parse(stdout);

  const startDate = data.start;
  const endDate = data.end;
  const prefixesByCalendars = data.prefixes;
  const calendarsByLists = data.lists;
  const remindersByIds = data.reminders;
  const eventsByIds = data.events;

  const syncMarker = '🔄';

  const originalEvents = [];
  const originalIds = [];
  const syncedEvents = [];
  const syncedIds = [];

  eventsByIds.forEach((event) => {
    let id = `${event.created}:${event.title}`;

    if (event.notes && event.notes.includes(syncMarker)) {
      syncedIds.push(id);
      syncedEvents.push(event);
    } else {
      originalIds.push(id);
      originalEvents.push(event);
    }
  });

  console.log({originalEvents});
  console.log({syncedEvents});

  const familySources = ['Garbage', 'Holidays', 'Birthdays'];
  const personalSources = ['Counselling', 'Massage'];

  const sourcesByTargets = {
    Family: familySources,
    Nick: personalSources,
  };

  const eventsToCreate = [];

  for (const targetCalendar in sourcesByTargets) {
    if (sourcesByTargets.hasOwnProperty(targetCalendar)) {
      const sources = sourcesByTargets[targetCalendar];

      const events = originalEvents.filter((event) => {
        return sources.includes(event.calendar) && !event.canceled;
      });

      events.forEach((source) => {
        let isSynced = syncedIds.includes(`${source.created}:${source.title}`);

        if (!isSynced) {
          eventsToCreate.push({
            calendar: targetCalendar,
            title: `${prefixesByCalendars[targetCalendar]} ${source.title}`,
            start: source.start,
            end: source.end,
            location: source.location,
            notes: source.notes ? `${source.notes}\n${syncMarker}` : syncMarker,
            allday: source.allday,
            canceled: source.canceled,
            status: source.status,
          });
        }
      });
    }
  }

  console.log({ eventsToCreate });

  fs.writeFile(
    '/Users/nick/Library/Mobile Documents/iCloud~is~workflow~my~workflows/Documents/syncer.json',
    JSON.stringify({ List: eventsToCreate }),
    'utf8',
    () => {},
  );

  const cmd = `echo "" | shortcuts run EventCreator | cat`;

  exec(cmd, (error, stdout, stderr) => {
    if (error) {
      console.log(`error: ${error.message}`);
      return;
    }

    if (stderr) {
      console.log(`stderr: ${stderr}`);
      return;
    }

    console.log(stdout);
  });
});
