"use strict";
//Audio doesn't work on Safari.
//SOUND CONTROLS
   
var AudioContext = window.AudioContext || window.webkitAudioContext;
var context = new AudioContext(); 

function playFile(filepath) {
  // see https://jakearchibald.com/2016/sounds-fun/
  // Fetch the file
  fetch(filepath)
    // Read it into memory as an arrayBuffer
    .then((response) => response.arrayBuffer())
    // Turn it from mp3/aac/whatever into raw audio data
    .then((arrayBuffer) =>      {    
          context.decodeAudioData(arrayBuffer, audioBuffer => {
          const soundSource = context.createBufferSource();
          soundSource.buffer = audioBuffer;
          soundSource.connect(context.destination);
          soundSource.start();
            },
            error =>
              console.error(error)
          )})
    // .then((audioBuffer) => {
    //   // Now we're ready to play!
    //   const soundSource = context.createBufferSource();
    //   soundSource.buffer = audioBuffer;
    //   soundSource.connect(context.destination);
    //   soundSource.start();
    // });
}

let soundOn = false;
function downloadSound(event) {
  if (soundOn) {
    document.querySelector(".turn-sound-on-btn").innerHTML ="Turn On Sound";
    playFile("https://watdoing.com/Untitled.m4a");
    soundOn = false;
  } else {
    soundOn = true;
    document.querySelector(".turn-sound-on-btn").innerHTML ="Turn Off Sound";
    playFile("https://watdoing.com/Untitled.m4a");
  }
}

//FLIP FLAP
let flap = document.querySelector(".split-flap-wrapper");

function setup(currentPos, symbolOrder, target) {
  for (let [index, item] of [...flap.children].entries()) {
    console.log(index);
    let SVG_POS = 7;
    if (index === SVG_POS) {
      continue;
    }

    let symbolCursor = symbolOrder.indexOf(currentPos[index]);
    //Get DOM element/
    let top_flap_queued = item.querySelector(".top-flap-queued");
    let top_flap_visible = item.querySelector(".top-flap-visible");
    let bottom_flap_queued = item.querySelector(".bottom-flap-queued");
    let bottom_flap_visible = item.querySelector(".bottom-flap-visible");

    //SETUP
    top_flap_visible.innerHTML = `<span>${symbolOrder[symbolCursor]}</span>`;
    top_flap_queued.innerHTML = `<span>${
      symbolOrder[(symbolCursor + 1) % symbolOrder.length]
    }</span>`;
    bottom_flap_queued.innerHTML = `<span>${
      symbolOrder[(symbolCursor + 1) % symbolOrder.length]
    }</span>`;
    bottom_flap_visible.innerHTML = `<span>${currentPos[index]}</span>`;

    if (top_flap_visible.innerHTML !== `<span>${target[index]}</span>`) {
      console.log(
        bottom_flap_visible,
        "wor",
        currentPos[index],
        currentPos,
        index
      );
      top_flap_visible.classList.remove("top-flap-animation");
      void top_flap_visible.offsetWidth;
      top_flap_visible.classList.add("top-flap-animation");
    }

    if (bottom_flap_visible.innerHTML !== `<span>${target[index]}</span>`) {
      console.log(
        bottom_flap_visible,
        "wor",
        currentPos[index],
        currentPos,
        index
      );
      bottom_flap_queued.classList.remove("bottom-flap-animation");
      void bottom_flap_queued.offsetWidth;
      bottom_flap_queued.classList.add("bottom-flap-animation");
    }

    function updateTopFlaps(e) {
      top_flap_visible.innerHTML = `<span>${
        symbolOrder[(symbolCursor + 1) % symbolOrder.length]
      }</span>`;
      top_flap_queued.innerHTML = `<span>${
        symbolOrder[(symbolCursor + 2) % symbolOrder.length]
      }</span>`;
    }

    top_flap_visible.addEventListener("animationend", updateTopFlaps);

    function updateBottomFlaps(e) {
      bottom_flap_visible.innerHTML = `<span>${
        symbolOrder[(symbolCursor + 1) % symbolOrder.length]
      }</span>`;
      bottom_flap_queued.innerHTML = `<span>${
        symbolOrder[(symbolCursor + 2) % symbolOrder.length]
      }</span>`;

      //run a check if we landed on the correct position.
      if (top_flap_visible.innerHTML === `<span>${target[index]}</span>`) {
        console.log(`${index} arived`);
        top_flap_visible.removeEventListener("animationend", updateTopFlaps);
        bottom_flap_queued.removeEventListener(
          "animationend",
          updateBottomFlaps
        );
        return;
      } else {
        function resetAnimation() {
          if (soundOn) {
            //I sampled this from my flip clock lol
            playFile('https://watdoing.com/Untitled.m4a');
          } 
          top_flap_visible.classList.remove("top-flap-animation");
          void top_flap_visible.offsetWidth;
          top_flap_visible.classList.add("top-flap-animation");
          bottom_flap_queued.classList.remove("bottom-flap-animation");
          void bottom_flap_queued.offsetWidth;
          bottom_flap_queued.classList.add("bottom-flap-animation");
        }
        symbolCursor++;
        resetAnimation();
      }
    }

    //STEP 3
    bottom_flap_queued.addEventListener("animationend", updateBottomFlaps);

    if (top_flap_visible.innerHTML === `<span>${target[index]}</span>`) {
      top_flap_visible.removeEventListener("animationend", updateTopFlaps);
      bottom_flap_queued.removeEventListener("animationend", updateBottomFlaps);
    }

    if (bottom_flap_visible.innerHTML === `<span>${target[index]}</span>`) {
      top_flap_visible.removeEventListener("animationend", updateTopFlaps);
      bottom_flap_queued.removeEventListener("animationend", updateBottomFlaps);
    }
  }
}

let alphabet =
  "abcdefghijklmnopqrstuvwxyz🕺ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-=_~!@#$%^&*?";

const splitEmoji = (string) => {
if (!!Intl?.Segmenter) {
  return[...new Intl.Segmenter().segment(string)].map((x) => x.segment);
} else {
  return [...string.replace(/[^a-z0-9-=_~!@#$%^&*?]/gi, '').split("")];
  //firefox doesn't support Intl.segmenter, default to alphanumerial.
}
}

function handleInput(e) {
  e.preventDefault();
  let input = e.target.inputText.value;
  input = input.replaceAll(" ", "_");
  console.log(input);

  setup(
    [...new Array(input.length).fill("a")],
    splitEmoji(alphabet),
    [...splitEmoji(input), "a", "a", "a", "a", "a", "a", "a"].splice(0, 8)
  );
}

function scaleUp(event) {
  let value = event.target.value;
  // console.log(value);
  event.preventDefault();
  if (value == "small") {
    document.querySelector(".split-flap-wrapper").style.transform =
      "scale(0.45)";
  }
  if (value == "medium") {
    console.log("fired medium");
    document.querySelector(".split-flap-wrapper").style.transform =
      "scale(0.6)";
  }
  if (value == "large") {
    document.querySelector(".split-flap-wrapper").style.transform = "scale(1)";
  }
}

const SplitFlapCharacters = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '🕺', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '-', '=', '_', '~', '!', '@', '#', '$', '%', '^', '&', '*', '?']

//Fire once for demo / preview - remove to disable preview text
setup([...new Array(7).fill("a")], SplitFlapCharacters, [
  "A",
  "w",
  "e",
  "s",
  "o",
  "m",
  "e"
]);