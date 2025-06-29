# Airport-Style Transcript Display

A beautiful, authentic airport split-flap display that shows live conversation transcripts with stunning wave animations.

## Features

- **Authentic Split-Flap Animation**: Realistic airport-style character flips with 3D effects
- **Wave Animation**: Beautiful top-to-bottom cascading animation (2 seconds)
- **Responsive Design**: Automatically adapts to any screen size (optimized for vertical displays)
- **Real-time Updates**: Live connection to Supabase for conversation transcripts
- **Smart Chunking**: Breaks conversations into screen-sized chunks for optimal readability
- **Configurable Timing**: 11-second reading time per chunk

## Perfect For

- Exhibition displays
- Digital signage
- Live conversation visualization
- Interactive installations
- Demonstration screens

## Tech Stack

- **React 18** - Modern React with hooks
- **Supabase** - Real-time database and subscriptions
- **CSS Animations** - Custom split-flap animations with keyframes
- **Responsive Layout** - Flexbox grid system

## Configuration

The display automatically fetches from the `conversations` table and processes:
- Latest conversations ordered by timestamp
- Full transcript content broken into readable chunks
- Real-time updates for new conversations

## Timing

- **Animation**: 2 seconds (wave effect)
- **Reading**: 11 seconds (comfortable reading time)
- **Total Cycle**: 13 seconds per chunk

## Display

- Centered layout with light gray background
- Realistic shadow effects for depth
- Perfectly positioned letters in each flap element
- Professional airport terminal aesthetic

---

Built for the Wiktoria & Lars Ultra exhibition system.