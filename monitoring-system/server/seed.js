// Seed script — creates the initial staff/user accounts and sample kiosk data.
// Idempotent: safe to run repeatedly. Run with `npm run seed`.
import bcrypt from 'bcryptjs';
import { prisma } from './src/db.js';
import { parseHHMM } from './src/utils/dates.js';

const hash = (pw) => bcrypt.hashSync(pw, 12);

async function run() {
  const accounts = [
    ['admin@system.com', 'System Admin', 'Admin@123', 'admin'],
    ['secretary@system.com', 'Jane Secretary', 'Secretary@123', 'secretary'],
    ['user@example.com', 'John User', 'User@1234', 'user'],
  ];
  for (const [email, name, pw, role] of accounts) {
    const existing = await prisma.users.findUnique({ where: { email } });
    if (existing) {
      console.log(`= user ${email} (exists)`);
      continue;
    }
    await prisma.users.create({ data: { email, name, password_hash: hash(pw), role } });
    console.log(`+ user ${email} / ${pw}`);
  }

  // Backfill an initial status-history row for any submission missing one.
  const subs = await prisma.submissions.findMany({ include: { status_history: true } });
  for (const s of subs) {
    if (s.status_history.length === 0) {
      await prisma.submission_status_history.create({
        data: { submission_id: s.id, changed_by: s.user_id, from_status: null, to_status: s.status },
      });
      console.log(`+ status history for submission ${s.id}`);
    }
  }

  const channels = [
    ['NTV Uganda', 'https://ntv.co.ug/live-tv', 'other', 1],
    ['NBS TV', 'https://www.nbs.ug/live', 'other', 2],
    ['Spark TV', 'https://ntv.co.ug/spark-live-tv-2', 'other', 3],
    ['UBC TV', 'https://www.youtube.com/channel/UCehjvG_d36rOJj81HBcWV0A/live', 'youtube', 4],
    ['Bukedde TV', 'https://www.newvision.co.ug/tv/4', 'other', 5],
    ['TV West', 'https://www.bukedde.co.ug/tv/6', 'other', 6],
  ];
  for (const [name, stream_url, stream_type, sort_order] of channels) {
    const existing = await prisma.channels.findFirst({ where: { name } });
    if (existing) {
      console.log(`= channel ${name} (exists)`);
      continue;
    }
    await prisma.channels.create({ data: { name, stream_url, stream_type, sort_order } });
    console.log(`+ channel ${name}`);
  }

  const placeholder = await prisma.channels.findFirst({ where: { name: 'Sample Test Stream' } });
  if (placeholder) {
    await prisma.channels.delete({ where: { id: placeholder.id } });
    console.log('- removed placeholder "Sample Test Stream"');
  }

  const programCount = await prisma.programs.count();
  if (programCount === 0) {
    await prisma.programs.createMany({
      data: [
        {
          title: 'Morning Briefing', day: 'daily',
          start_time: parseHHMM('08:00'), end_time: parseHHMM('08:30'),
          location: 'Main Hall', description: 'Daily briefing for staff and visitors.',
        },
        {
          title: 'Public Service Hours', day: 'daily',
          start_time: parseHHMM('09:00'), end_time: parseHHMM('16:00'),
          location: 'Reception', description: 'Front desk open for visitor inquiries.',
        },
        {
          title: 'Community Outreach', day: 'friday',
          start_time: parseHHMM('14:00'), end_time: parseHHMM('16:00'),
          location: 'Seminar Room', description: 'Weekly outreach session.',
        },
      ],
    });
    console.log('+ 3 sample programs');
  } else {
    console.log(`= programs (${programCount} exist)`);
  }

  console.log('\nDatabase seeded.');
}

run()
  .catch((e) => {
    console.error(e);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
