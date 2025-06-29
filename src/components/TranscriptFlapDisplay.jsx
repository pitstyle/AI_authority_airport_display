import React, { useEffect, useRef, useState } from 'react';
import { createClient } from '@supabase/supabase-js';

const TranscriptFlapDisplay = ({ 
  supabaseUrl, 
  supabaseKey,
  animationSpeed = 100, // ms per character flip cycle
  readingTime = 11000, // 11 seconds to read each transcript
  totalAnimationTime = 2000 // 2 seconds total for wave animation
}) => {
  const containerRef = useRef(null);
  const [, setSupabase] = useState(null);
  const [isConnected, setIsConnected] = useState(false);
  const [textQueue, setTextQueue] = useState([]);
  const [isAnimating, setIsAnimating] = useState(false);
  const [allFlaps, setAllFlaps] = useState([]);
  const [currentText, setCurrentText] = useState('');
  const [conversations, setConversations] = useState([]);
  const [currentConversationIndex, setCurrentConversationIndex] = useState(0);
  const [currentChunks, setCurrentChunks] = useState([]);
  const [currentChunkIndex, setCurrentChunkIndex] = useState(0);
  const [isLooping, setIsLooping] = useState(false);
  const [gridDimensions, setGridDimensions] = useState({ charsPerRow: 0, totalRows: 0, totalFlaps: 0 });
  
  // Character set for split-flap display - exactly like original
  // const FLAP_CHARACTERS = 
  //   "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-=_~!@#$%^&*? ";
  
  // Grid dimension constants
  const FLAP_WIDTH = 80;
  const FLAP_HEIGHT = 85;
  const FLAP_MARGIN = 4; // 2px on each side
  const CONTAINER_PADDING = 20; // Container padding
  const WRAPPER_PADDING = 10; // Split-flap-wrapper padding

  // Calculate grid dimensions based on current viewport
  const calculateGridDimensions = () => {
    const SCREEN_WIDTH = window.innerWidth;
    const SCREEN_HEIGHT = window.innerHeight;
    
    // Calculate available space inside the wrapper
    const AVAILABLE_WIDTH = SCREEN_WIDTH - (CONTAINER_PADDING * 2) - (WRAPPER_PADDING * 2);
    const AVAILABLE_HEIGHT = SCREEN_HEIGHT - (CONTAINER_PADDING * 2) - (WRAPPER_PADDING * 2);
    
    const charsPerRow = Math.floor(AVAILABLE_WIDTH / (FLAP_WIDTH + FLAP_MARGIN));
    const totalRows = Math.floor(AVAILABLE_HEIGHT / (FLAP_HEIGHT + FLAP_MARGIN));
    const totalFlaps = charsPerRow * totalRows;
    
    console.log(`Grid calculation: ${SCREEN_WIDTH}x${SCREEN_HEIGHT} -> ${charsPerRow} cols x ${totalRows} rows = ${totalFlaps} flaps`);
    
    return { charsPerRow, totalRows, totalFlaps };
  };

  // Supabase connection setup
  useEffect(() => {
    if (!supabaseUrl || !supabaseKey) return;
    
    const initSupabase = async () => {
      try {
        const client = createClient(supabaseUrl, supabaseKey);
        
        // Test connection
        const { error } = await client.from('transcripts').select('count').limit(1);
        if (error) throw error;
        
        setSupabase(client);
        setIsConnected(true);
        console.log('Connected to Supabase successfully');
        
        // Load initial conversations
        loadInitialConversations(client);
        
        // Setup real-time subscription
        setupRealtimeSubscription(client);
        
      } catch (error) {
        console.error('Supabase connection failed:', error);
        displayText(`CONNECTION ERROR: ${error.message}`);
      }
    };
    
    initSupabase();
  }, [supabaseUrl, supabaseKey]); // eslint-disable-line react-hooks/exhaustive-deps

  const loadInitialConversations = async (client) => {
    try {
      const { data, error } = await client
        .from('conversations')
        .select('id, user_name, topic, full_transcript, start_time')
        .not('full_transcript', 'is', null)
        .order('start_time', { ascending: false })
        .limit(20);

      if (error) throw error;

      if (data && data.length > 0) {
        console.log(`Loading ${data.length} conversations`);
        setConversations(data);
        
        // Process first conversation after a short delay to ensure grid is ready
        setTimeout(() => {
          if (data[0]) {
            processConversation(data[0]);
          }
        }, 100);
        
        // Clear the initial message first
        clearAllFlaps();
        setCurrentText('');
        
        // Start the looping animation
        setIsLooping(true);
      }
    } catch (error) {
      console.error('Failed to load conversations:', error);
    }
  };

  const processConversation = (conversation) => {
    if (!conversation || !conversation.full_transcript || !conversation.full_transcript.results) {
      console.log('No transcript results found');
      return;
    }

    // Extract all messages and format them
    const messages = conversation.full_transcript.results
      .filter(msg => msg.text) // Only messages with text
      .map(msg => `${msg.speaker_label}: ${msg.text}`);
    
    if (messages.length === 0) {
      console.log('No valid messages found in conversation');
      return;
    }
    
    // Break into screen-sized chunks
    const chunks = breakIntoChunks(messages.join(' '));
    setCurrentChunks(chunks);
    setCurrentChunkIndex(0);
    
    console.log(`Processed conversation: ${chunks.length} chunks`);
  };

  const breakIntoChunks = (fullText) => {
    const maxCharsPerScreen = gridDimensions.totalFlaps || 1000; // fallback if grid not ready
    const chunks = [];
    
    if (maxCharsPerScreen <= 0) {
      return [fullText]; // return as single chunk if grid not ready
    }
    
    for (let i = 0; i < fullText.length; i += maxCharsPerScreen) {
      chunks.push(fullText.slice(i, i + maxCharsPerScreen));
    }
    
    return chunks;
  };

  const setupRealtimeSubscription = (client) => {
    client
      .channel('conversations')
      .on('postgres_changes', {
        event: 'UPDATE',
        schema: 'public',
        table: 'conversations'
      }, (payload) => {
        console.log('Conversation updated:', payload.new);
        // Add new conversation to the beginning of the list
        if (payload.new.full_transcript) {
          setConversations(prev => [payload.new, ...prev]);
        }
      })
      .subscribe((status) => {
        console.log('Subscription status:', status);
        if (status === 'SUBSCRIBED') {
          // Clear initial message when ready
          setTimeout(() => {
            clearAllFlaps();
            setCurrentText('');
          }, 500);
        }
      });
  };

  const displayText = (text) => {
    // Add complete text chunks to queue
    setTextQueue(prev => [...prev, text.toUpperCase()]);
  };

  // Process text queue (legacy - keeping for compatibility)
  useEffect(() => {
    if (textQueue.length === 0 || isAnimating) return;
    
    const processNext = async () => {
      setIsAnimating(true);
      const nextText = textQueue[0];
      await animateToText(nextText);
      setTextQueue(prev => prev.slice(1));
      
      // Much shorter pause between chunks
      setTimeout(() => {
        setIsAnimating(false);
      }, 1000);
    };
    
    processNext();
  }, [textQueue, isAnimating]); // eslint-disable-line react-hooks/exhaustive-deps

  // Continuous looping animation of conversation chunks
  useEffect(() => {
    if (!isLooping || currentChunks.length === 0 || isAnimating) return;
    
    const loopChunks = async () => {
      setIsAnimating(true);
      
      // Get current chunk
      const currentChunk = currentChunks[currentChunkIndex];
      await animateToText(currentChunk);
      
      // Move to next chunk
      const nextChunkIndex = currentChunkIndex + 1;
      
      if (nextChunkIndex >= currentChunks.length) {
        // Current conversation finished, move to next conversation
        const nextConversationIndex = (currentConversationIndex + 1) % conversations.length;
        setCurrentConversationIndex(nextConversationIndex);
        
        if (conversations[nextConversationIndex]) {
          processConversation(conversations[nextConversationIndex]);
        }
      } else {
        // Move to next chunk in same conversation
        setCurrentChunkIndex(nextChunkIndex);
      }
      
      // Pause for reading time
      setTimeout(() => {
        setIsAnimating(false);
      }, readingTime); // 11 second pause between chunks
    };
    
    loopChunks();
  }, [isLooping, currentChunks, currentChunkIndex, isAnimating, conversations, currentConversationIndex]); // eslint-disable-line react-hooks/exhaustive-deps

  // Initialize flaps grid
  const initializeFlapsGrid = () => {
    if (!containerRef.current) return;
    
    // Calculate current grid dimensions
    const dimensions = calculateGridDimensions();
    setGridDimensions(dimensions);
    
    const container = containerRef.current;
    const wrapperDiv = container.querySelector('.split-flap-wrapper') || createWrapperDiv();
    
    // Clear existing flaps
    const existingFlaps = wrapperDiv.querySelectorAll('.flap');
    existingFlaps.forEach(flap => flap.remove());
    
    // Create grid of flaps and store references
    const flapsArray = [];
    console.log(`Creating ${dimensions.totalFlaps} flaps (${dimensions.charsPerRow} x ${dimensions.totalRows})`);
    
    for (let i = 0; i < dimensions.totalFlaps; i++) {
      const flapDiv = createFlapElement(i);
      wrapperDiv.appendChild(flapDiv);
      flapsArray.push(flapDiv);
    }
    
    console.log(`Created ${flapsArray.length} flap elements`);
    setAllFlaps(flapsArray);
  };

  const createWrapperDiv = () => {
    if (!containerRef.current) return null;
    
    containerRef.current.innerHTML = '';
    const wrapperDiv = document.createElement('div');
    wrapperDiv.className = 'split-flap-wrapper flex-center-all';
    containerRef.current.appendChild(wrapperDiv);
    return wrapperDiv;
  };

  const createFlapElement = (index) => {
    const flapDiv = document.createElement('div');
    flapDiv.className = 'flap flex-center-all';
    flapDiv.setAttribute('data-index', index);
    flapDiv.innerHTML = `
      <div class="top">
        <div class="top-flap-queued">
          <span> </span>
        </div>
        <div class="top-flap-visible">
          <span> </span>
        </div>
      </div>
      <div class="bottom">
        <div class="bottom-flap-queued">
          <span> </span>
        </div>
        <div class="bottom-flap-visible">
          <span> </span>
        </div>
      </div>
    `;
    return flapDiv;
  };

  // Animate complete text - ALL flaps flip simultaneously
  const animateToText = async (targetText) => {
    return new Promise((resolve) => {
      if (!allFlaps || allFlaps.length === 0) {
        console.log('No flaps available for animation');
        resolve();
        return;
      }

      console.log(`Animating text: "${targetText}" to ${allFlaps.length} flaps`);

      // Prepare current array - pad with spaces
      const currentArray = currentText.split('').slice(0, gridDimensions.totalFlaps);
      while (currentArray.length < gridDimensions.totalFlaps) {
        currentArray.push(' ');
      }
      
      // Prepare target array - repeat text to fill all flaps if needed
      const targetArray = [];
      const textWithSpaces = targetText + '    '; // Add spacing between repetitions
      
      for (let i = 0; i < gridDimensions.totalFlaps; i++) {
        targetArray.push(textWithSpaces[i % textWithSpaces.length]);
      }

      console.log(`Target array length: ${targetArray.length}, Flaps available: ${allFlaps.length}`);

      let completedFlaps = 0;
      const totalFlapsToAnimate = allFlaps.length;

      // Calculate wave animation timing
      const waveDelayPerRow = totalAnimationTime / gridDimensions.totalRows;
      
      console.log(`Wave animation: ${totalAnimationTime}ms total, ${waveDelayPerRow}ms per row`);

      // Animate flaps with wave effect (top to bottom)
      allFlaps.forEach((flap, index) => {
        const currentChar = currentArray[index] || ' ';
        const targetChar = targetArray[index] || ' ';
        
        // Calculate which row this flap is in
        const row = Math.floor(index / gridDimensions.charsPerRow);
        const waveDelay = row * waveDelayPerRow;

        // Debug first few flaps
        if (index < 10) {
          console.log(`Flap ${index} (row ${row}): "${currentChar}" -> "${targetChar}", delay: ${waveDelay}ms`);
        }

        // Start animation with wave delay
        setTimeout(() => {
          animateFlap(flap, currentChar, targetChar, () => {
            completedFlaps++;
            if (completedFlaps === totalFlapsToAnimate) {
              setCurrentText(targetText);
              setTimeout(resolve, 50);
            }
          });
        }, waveDelay);
      });
    });
  };
  
  const clearAllFlaps = () => {
    allFlaps.forEach(flap => {
      clearFlap(flap);
    });
    setCurrentText('');
  };

  const clearFlap = (flap) => {
    const topVisible = flap.querySelector('.top-flap-visible span');
    const topQueued = flap.querySelector('.top-flap-queued span');
    const bottomVisible = flap.querySelector('.bottom-flap-visible span');
    const bottomQueued = flap.querySelector('.bottom-flap-queued span');
    
    if (topVisible) topVisible.innerHTML = ' ';
    if (topQueued) topQueued.innerHTML = ' ';
    if (bottomVisible) bottomVisible.innerHTML = ' ';
    if (bottomQueued) bottomQueued.innerHTML = ' ';
  };

  // Animate single flap - following original CodePen logic
  const animateFlap = (flap, currentChar, targetChar, onComplete) => {
    const topVisible = flap.querySelector('.top-flap-visible');
    const topQueued = flap.querySelector('.top-flap-queued');
    const bottomVisible = flap.querySelector('.bottom-flap-visible');
    const bottomQueued = flap.querySelector('.bottom-flap-queued');
    
    const topVisibleSpan = topVisible.querySelector('span');
    const topQueuedSpan = topQueued.querySelector('span');
    const bottomVisibleSpan = bottomVisible.querySelector('span');
    const bottomQueuedSpan = bottomQueued.querySelector('span');

    // ULTRA FAST - skip cycling, go directly to target
    topVisibleSpan.innerHTML = targetChar;
    topQueuedSpan.innerHTML = targetChar;
    bottomVisibleSpan.innerHTML = targetChar;
    bottomQueuedSpan.innerHTML = targetChar;
    
    // Quick flip animation
    topVisible.classList.add('top-flap-animation');
    bottomQueued.classList.add('bottom-flap-animation');
    
    // Complete immediately after animation
    setTimeout(() => {
      topVisible.classList.remove('top-flap-animation');
      bottomQueued.classList.remove('bottom-flap-animation');
      onComplete();
    }, 50); // Fast individual flap animation
  };

  // Initialize on mount
  useEffect(() => {
    if (!containerRef.current) return;
    
    initializeFlapsGrid();
    
    // Show initial message only if not connected
    if (!isConnected) {
      displayText('SYSTEM READY - CONNECTING...');
    }
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  // Reinitialize on resize
  useEffect(() => {
    const handleResize = () => {
      setTimeout(() => {
        initializeFlapsGrid();
      }, 100);
    };
    
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <>
      {/* CSS Styles - Exact copy from original CodePen */}
      <style>{`
        @keyframes flip {
          from {
            transform: rotateX(-0deg);
          }
          to {
            transform: rotateX(-90deg);
          }
        }

        @keyframes bflip {
          from {
            transform: rotateX(90deg);
          }
          to {
            transform: rotateX(0deg);
          }
        }

        * {
          box-sizing: border-box;
          padding: 0px;
          margin: 0px;
        }
        
        body, html {
          background-color: #CCCCCC;
          width: 100vw;
          height: 100vh;
          display: flex;
          justify-content: center;
          align-items: center;
        }
        
        .transcript-split-flap-container {
          width: 100vw;
          height: 100vh;
          background-color: #CCCCCC;
          color: #DDDDDD;
          display: flex;
          justify-content: center;
          align-items: center;
          padding: 20px;
          overflow: hidden;
          margin: 0 auto;
        }
        
        .flex-center-all {
          display: flex;
          justify-content: center;
          align-items: center;
        }
        
        .split-flap-wrapper {
          width: 100%;
          height: 100%;
          border: 1px solid black;
          padding: 10px;
          background: radial-gradient(#404040, black);
          box-shadow: 
            inset 2px 2px 15px #444444,
            8px 8px 20px rgba(0, 0, 0, 0.3);
          border-bottom: 5px solid black;
          border-right: 5px solid black;
          border-radius: 5px;
          flex-shrink: 0;
          overflow: hidden;
          display: flex;
          flex-wrap: wrap;
          align-content: center;
          justify-content: center;
        }
        
        .flap {
          width: 80px;
          height: 85px;
          border: 2px solid black;
          margin: 2px;
          font-size: 60px;
          flex-direction: column;
          display: flex;
          background-color: black;
          perspective: 700px;
          overflow: hidden;
          border-radius: 4px;
          box-shadow: inset 2px 2px #111111;
          padding: 4px;
          flex-shrink: 0;
        }
        
        .top {
          border-bottom: 1px solid #222222;
          box-shadow: inset 0px -1px white;
          width: 100%;
          height: 50%;
          text-align: center;
          position: relative;
          overflow: hidden;
          background-color: black;
        }
        
        .bottom {
          width: 100%;
          height: 50%;
          text-align: center;
          position: relative;
          overflow: hidden;
          background-color: black;
        }
        
        .top-flap-visible,
        .top-flap-queued {
          position: absolute;
          top: 0px;
          left: 0px;
          height: 100%;
          width: 100%;
          background-color: rgb(10,10,10);
          z-index: 2;
          border-radius: 15px;
          border-top: 1px solid #333333;
          display: flex;
          align-items: center;
          justify-content: center;
          color: #DDDDDD;
        }
        
        .top-flap-queued {
          z-index: 1;
        }
        
        .bottom-flap-visible,
        .bottom-flap-queued {
          position: absolute;
          top: 0px;
          left: 0px;
          height: 100%;
          width: 100%;
          background: radial-gradient(#404040, black);
          z-index: 1;
          overflow: hidden;
          border-radius: 15px;
          border-bottom: 1px solid #333333;
          display: flex;
          align-items: center;
          justify-content: center;
          color: #DDDDDD;
        }
        
        .top span {
          display: block;
          margin-top: 43%;
        }
        
        .bottom span {
          display: block;
          margin-top: -52%;
        }
        
        .bottom-flap-queued {
          z-index: 2;
          transform: rotateX(90deg);
          overflow: hidden;
        }
        
        .top-flap-animation {
          animation: flip ${animationSpeed}ms ease-in;
          transform-origin: bottom;
        }
        
        .bottom-flap-animation {
          animation: bflip ${animationSpeed}ms ease-in;
          transform-origin: top;
          animation-delay: ${animationSpeed}ms;
        }
      `}</style>
      
      <div 
        ref={containerRef}
        className="transcript-split-flap-container"
      />
    </>
  );
};

export default TranscriptFlapDisplay;