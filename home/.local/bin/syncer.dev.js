#!/usr/bin/env node

const { exec } = require('child_process');

const eventsToCreate = [
  {
    calendar: 'Nick',
    title: '🎗️ Individual Counselling Session',
    start: '2024-04-08T14:00:00-07:00',
    end: '2024-04-08T14:50:00-07:00',
    location: 'Trauma and Stress Counselling - 8029 199 St, Langley Township',
    notes: '🔄',
    allday: false,
    canceled: false,
    status: '',
  },
  {
    calendar: 'Family',
    title: '❤️  Recycling, garbage cart, and green cart',
    start: '2024-04-10T00:00:00-07:00',
    end: '2024-04-10T23:59:59-07:00',
    location: '',
    notes: 'Recycling, garbage cart, and green cart\n🔄',
    allday: true,
    canceled: false,
    status: '',
  },
];



