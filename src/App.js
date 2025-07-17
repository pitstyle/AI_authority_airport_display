import React, { useState, useEffect } from 'react';
import TranscriptFlapDisplay from './components/TranscriptFlapDisplay';
import { SUPABASE_CONFIG, validateConfig } from './config';

function App() {
  const [configError, setConfigError] = useState(null);
  const [isConfigValid, setIsConfigValid] = useState(false);

  useEffect(() => {
    try {
      validateConfig();
      setIsConfigValid(true);
      console.log('Supabase configuration validated successfully');
    } catch (error) {
      setConfigError(error.message);
      console.error('Configuration error:', error.message);
    }
  }, []);

  if (configError) {
    return (
      <div style={{
        width: '100vw',
        height: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: '#f8f9fa',
        fontFamily: '"Courier New", monospace',
        padding: '20px',
        boxSizing: 'border-box'
      }}>
        <div style={{
          backgroundColor: '#fff',
          border: '2px solid #dc3545',
          borderRadius: '8px',
          padding: '30px',
          maxWidth: '600px',
          textAlign: 'center'
        }}>
          <h1 style={{ color: '#dc3545', marginBottom: '20px' }}>
            Configuration Error
          </h1>
          <p style={{ 
            color: '#6c757d', 
            marginBottom: '20px',
            lineHeight: '1.5'
          }}>
            {configError}
          </p>
          <div style={{
            backgroundColor: '#f8f9fa',
            border: '1px solid #dee2e6',
            borderRadius: '4px',
            padding: '15px',
            textAlign: 'left',
            fontSize: '14px'
          }}>
            <strong>Setup Instructions:</strong>
            <ol style={{ marginTop: '10px', paddingLeft: '20px' }}>
              <li>Edit <code>src/config.js</code></li>
              <li>Replace the URL and ANON_KEY values with your Supabase credentials</li>
              <li>Or set environment variables:
                <ul style={{ marginTop: '5px' }}>
                  <li><code>REACT_APP_SUPABASE_URL</code></li>
                  <li><code>REACT_APP_SUPABASE_ANON_KEY</code></li>
                </ul>
              </li>
              <li>Restart the development server</li>
            </ol>
          </div>
        </div>
      </div>
    );
  }

  if (!isConfigValid) {
    return (
      <div style={{
        width: '100vw',
        height: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: '#fff',
        fontFamily: '"Courier New", monospace',
        fontSize: '24px',
        color: '#6c757d'
      }}>
        Validating configuration...
      </div>
    );
  }

  return (
    <TranscriptFlapDisplay 
      supabaseUrl={SUPABASE_CONFIG.URL}
      supabaseKey={SUPABASE_CONFIG.ANON_KEY}
      animationSpeed={SUPABASE_CONFIG.ANIMATION_SPEED}
      displayId={SUPABASE_CONFIG.DISPLAY_ID}
      totalDisplays={SUPABASE_CONFIG.TOTAL_DISPLAYS}
      displayScale={SUPABASE_CONFIG.DISPLAY_SCALE}
    />
  );
}

export default App;