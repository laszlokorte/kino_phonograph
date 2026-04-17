const numf = new Intl.NumberFormat("en-US", {
  maximumFractionDigits: 2,
  minimumFractionDigits: 2,
});

export function init(ctx, args) {
  ctx.importCSS("audio.css");

  if (args.titel) {
    const t = document.createElement("h3");
    t.appendChild(document.createTextNode(args.titel));
    ctx.root.appendChild(t);
  }
  for (let track of args.tracks) {
    const row = document.createElement("div");
    row.classList.add("row");

    if (track.label) {
      const l = document.createElement("h3");
      l.appendChild(document.createTextNode(track.label));
      row.appendChild(l);
    }

    if (args.show_meta) {
      const dl = document.createElement("dl");
      dl.classList.add("meta-list");

      {
        const dt = document.createElement("dt");
        dt.appendChild(document.createTextNode("Channels"));

        const dd = document.createElement("dt");
        dd.appendChild(document.createTextNode(track.samples.length));

        dl.appendChild(dt);
        dl.appendChild(dd);
      }

      {
        const dt = document.createElement("dt");
        dt.appendChild(document.createTextNode("Samples"));

        const dd = document.createElement("dt");
        dd.appendChild(document.createTextNode(track.samples[0]?.length ?? 0));

        dl.appendChild(dt);
        dl.appendChild(dd);
      }

      {
        const dt = document.createElement("dt");
        dt.appendChild(document.createTextNode("Sampling Rate"));

        const dd = document.createElement("dt");
        dd.appendChild(document.createTextNode(track.sample_rate));
        dd.appendChild(document.createTextNode(" Hz"));

        dl.appendChild(dt);
        dl.appendChild(dd);
      }

      {
        const dt = document.createElement("dt");
        dt.appendChild(document.createTextNode("Duration"));

        const dd = document.createElement("dt");
        dd.appendChild(
          document.createTextNode(
            numf.format((track.samples[0]?.length ?? 0) / track.sample_rate),
          ),
        );
        dd.appendChild(document.createTextNode(" seconds"));

        dl.appendChild(dt);
        dl.appendChild(dd);
      }
      row.appendChild(dl);
    }

    const a = document.createElement("audio");
    a.setAttribute("controls", true);
    if (track.loop) {
      a.setAttribute("loop", true);
    }

    const samples = track.samples.map((t) => new Float32Array(t));

    const wavBuffer = samplesToWav(samples, track.sample_rate);
    const blob = new Blob([wavBuffer], { type: "audio/wav" });

    const url = URL.createObjectURL(blob);
    a.setAttribute("src", url);

    row.appendChild(a);
    ctx.root.appendChild(row);
  }
}

function interleave(channels) {
  const numChannels = channels.length;
  const length = channels[0].length;

  const result = new Float32Array(length * numChannels);

  let offset = 0;
  for (let i = 0; i < length; i++) {
    for (let ch = 0; ch < numChannels; ch++) {
      result[offset++] = channels[ch][i];
    }
  }

  return result;
}

function samplesToWav(channels, sampleRate = 44100) {
  const numChannels = channels.length;
  const interleaved = interleave(channels);

  const bytesPerSample = 2;
  const blockAlign = numChannels * bytesPerSample;
  const byteRate = sampleRate * blockAlign;

  const buffer = new ArrayBuffer(44 + interleaved.length * bytesPerSample);
  const view = new DataView(buffer);

  function writeString(offset, str) {
    for (let i = 0; i < str.length; i++) {
      view.setUint8(offset + i, str.charCodeAt(i));
    }
  }

  let offset = 0;

  writeString(offset, "RIFF");
  offset += 4;
  view.setUint32(offset, 36 + interleaved.length * bytesPerSample, true);
  offset += 4;
  writeString(offset, "WAVE");
  offset += 4;

  writeString(offset, "fmt ");
  offset += 4;
  view.setUint32(offset, 16, true);
  offset += 4;
  view.setUint16(offset, 1, true);
  offset += 2; // PCM
  view.setUint16(offset, numChannels, true);
  offset += 2;
  view.setUint32(offset, sampleRate, true);
  offset += 4;
  view.setUint32(offset, byteRate, true);
  offset += 4;
  view.setUint16(offset, blockAlign, true);
  offset += 2;
  view.setUint16(offset, 16, true);
  offset += 2;

  writeString(offset, "data");
  offset += 4;
  view.setUint32(offset, interleaved.length * bytesPerSample, true);
  offset += 4;

  for (let i = 0; i < interleaved.length; i++, offset += 2) {
    let s = Math.max(-1, Math.min(1, interleaved[i]));
    view.setInt16(offset, s * 32767, true);
  }

  return buffer;
}
