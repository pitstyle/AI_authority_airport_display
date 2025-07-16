// Supabase Configuration
// Replace these with your actual Supabase project credentials

export const SUPABASE_CONFIG = {
  // Your Supabase project URL
  URL: process.env.REACT_APP_SUPABASE_URL || 'https://your-project-id.supabase.co',
  
  // Your Supabase anon/public key
  ANON_KEY: process.env.REACT_APP_SUPABASE_ANON_KEY || 'your-anon-key-here',
  
  // Display settings
  ANIMATION_SPEED: 200, // ms per character flip
  INITIAL_LOAD_LIMIT: 20, // Number of initial transcripts to load
  
  // Multi-display configuration
  DISPLAY_ID: parseInt(process.env.REACT_APP_DISPLAY_ID) || 1, // Which display this is (1, 2, or 3)
  TOTAL_DISPLAYS: 3, // Total number of displays
  
  // Real-time subscription settings
  REALTIME_CHANNEL: 'transcripts',
  
  // Database table configuration
  TABLE_NAME: 'transcripts',
  REQUIRED_FIELDS: ['content', 'speaker', 'timestamp']
};

// Validation function
export const validateConfig = () => {
  const { URL, ANON_KEY } = SUPABASE_CONFIG;
  
  if (!URL || URL === 'https://your-project-id.supabase.co') {
    throw new Error('Please set your Supabase URL in src/config.js or REACT_APP_SUPABASE_URL environment variable');
  }
  
  if (!ANON_KEY || ANON_KEY === 'your-anon-key-here') {
    throw new Error('Please set your Supabase anon key in src/config.js or REACT_APP_SUPABASE_ANON_KEY environment variable');
  }
  
  return true;
};