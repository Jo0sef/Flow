// Flow extractors. Plain JavaScript, run inside the app (JavaScriptCore).
// Updatable: Settings > Downloads > Update extractors fetches the newest copy of this file.
// Bridge provided by the app: http({url, method, headers, body}) -> Promise<{status, headers, text, url}>
// Each extractor returns {title, thumb, duration, uploader, formats:[...]}
// format: {id, kind:'muxed'|'video'|'audio', label, detail, ext, size, height, url, headers}
var FLOW_VERSION = 11;
// FLOW_MIN_NATIVE (optional): lowest app native level this file needs. Older apps skip the file.
function flowSelfTest() { return typeof http === "function" && typeof flowExtract === "function"; }
var UA_IOS = 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1';
var UA_DESK = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Safari/605.1.15';

function fixEsc(s) {
  return s.replace(/\\u([0-9a-fA-F]{4})/g, function (m, h) { return String.fromCharCode(parseInt(h, 16)); })
          .replace(/\\\//g, '/').replace(/\\"/g, '"').replace(/&amp;/g, '&').replace(/\\\\/g, '\\');
}
function human(n) { return n; }

// ---------- YouTube ----------
function ytId(u) {
  var m = u.match(/(?:youtu\.be\/|[?&]v=|\/shorts\/|\/embed\/|\/live\/|\/v\/)([A-Za-z0-9_-]{11})/);
  return m ? m[1] : null;
}
var YT_CLIENTS = [
  { name: 'visionos', ctx: { clientName: 'VISIONOS', clientVersion: '1.02', deviceMake: 'Apple', deviceModel: 'RealityDevice17,1', osName: 'visionOS', osVersion: '26.5.23O471', hl: 'en' }, num: '101',
    ua: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15' },
  { name: 'android_vr', ctx: { clientName: 'ANDROID_VR', clientVersion: '1.60.19', deviceMake: 'Oculus', deviceModel: 'Quest 3', osName: 'Android', osVersion: '12L', androidSdkVersion: 32, hl: 'en' }, num: '28',
    ua: 'com.google.android.apps.youtube.vr.oculus/1.60.19 (Linux; U; Android 12L; eureka-user Build/SQ3A.220605.009.A1) gzip' },
  { name: 'ios', ctx: { clientName: 'IOS', clientVersion: '20.10.4', deviceMake: 'Apple', deviceModel: 'iPhone16,2', osName: 'iPhone', osVersion: '18.3.2.22D82', hl: 'en' }, num: '5',
    ua: 'com.google.ios.youtube/20.10.4 (iPhone16,2; U; CPU iOS 18_3_2 like Mac OS X;)' },
  { name: 'android', ctx: { clientName: 'ANDROID', clientVersion: '20.10.38', androidSdkVersion: 30, osName: 'Android', osVersion: '11', hl: 'en' }, num: '3',
    ua: 'com.google.android.youtube/20.10.38 (Linux; U; Android 11) gzip' },
  { name: 'mweb', ctx: { clientName: 'MWEB', clientVersion: '2.20250312.01.00', hl: 'en' }, num: '2',
    ua: 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_7 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1' },
  { name: 'tv_embedded', ctx: { clientName: 'TVHTML5_SIMPLY_EMBEDDED_PLAYER', clientVersion: '2.0', hl: 'en' }, num: '85', third: true,
    ua: 'Mozilla/5.0 (PlayStation; PlayStation 4/12.00) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.4 Safari/605.1.15' }
];
var YT_VISITOR = null;
async function ytVisitor() {
  if (YT_VISITOR !== null) return YT_VISITOR;
  YT_VISITOR = '';
  try {
    var r = await http({ url: 'https://www.youtube.com/', timeout: 8, headers: { 'User-Agent': UA_DESK, 'Accept-Language': 'en-US,en;q=0.9' } });
    var m = (r.text || '').match(/"visitorData"\s*:\s*"([^"]+)"/) || (r.text || '').match(/"VISITOR_DATA"\s*:\s*"([^"]+)"/);
    if (m) YT_VISITOR = m[1];
  } catch (e) { }
  return YT_VISITOR;
}
async function ytPlayer(id, c, vd) {
  var cl = JSON.parse(JSON.stringify(c.ctx)); if (vd) cl.visitorData = vd;
  var hd = { 'Content-Type': 'application/json', 'User-Agent': c.ua, 'X-YouTube-Client-Name': c.num, 'X-YouTube-Client-Version': c.ctx.clientVersion, 'Origin': 'https://www.youtube.com' };
  if (vd) hd['X-Goog-Visitor-Id'] = vd;
  var r = await http({ url: 'https://www.youtube.com/youtubei/v1/player?prettyPrint=false', method: 'POST', timeout: 8, headers: hd,
    body: JSON.stringify({ context: c.third ? { client: cl, thirdParty: { embedUrl: 'https://www.youtube.com/watch?v=' + id } } : { client: cl }, videoId: id, contentCheckOk: true, racyCheckOk: true }) });
  if (r.status !== 200) throw new Error('YouTube HTTP ' + r.status);
  return JSON.parse(r.text);
}
async function ytProbe(u, h) {
  var t0 = Date.now();
  try { var r = await http({ url: u, timeout: 6, headers: Object.assign({ Range: 'bytes=0-1' }, h) }); return { s: r.status, ms: Date.now() - t0 }; }
  catch (e) { return { s: 0, ms: Date.now() - t0, err: String((e && e.message) || e).slice(0, 60) }; }
}
// raw TCP+TLS probe made by the app (can force IPv4 / IPv6 / mobile data). Absent in older app builds.
function rawProbe(u, o) {
  return new Promise(function (res) {
    if (typeof __raw !== 'function') { res({ error: 'n/a' }); return; }
    var m = u.match(/^https:\/\/([^\/]+)(\/.*)$/); if (!m) { res({ error: 'bad url' }); return; }
    __raw({ host: o.host || m[1], path: m[2], family: o.family || 'any', range: o.range !== false, ua: o.ua, timeout: 5 }, function (r) { res(r || { error: 'none' }); });
  });
}
function rawDesc(label, r) {
  if (!r || r.error === 'n/a') return label + ': n/a';
  return label + ': ' + (r.status ? ('HTTP ' + r.status) : ('error ' + r.error)) + (r.addr ? (' ' + r.addr) : '') + ' ' + (r.ms || 0) + 'ms';
}
function gvHost(u) { var m = u.match(/^https:\/\/([^\/]+)\//); return m ? m[1] : ''; }
async function youtube(url) {
  var id = ytId(url);
  if (!id) throw new Error('Could not find the video id in this link');
  var d = null, lastReason = '', cands = [], plog = [], diagDone = false, allErr = true, loginCount = 0;
  for (var i = 0; i < YT_CLIENTS.length && !d; i++) {
    try {
      var tp = Date.now();
      var j = await ytPlayer(id, YT_CLIENTS[i]);
      var st = j.playabilityStatus && j.playabilityStatus.status;
      if (st === 'LOGIN_REQUIRED') {
        loginCount++;
        var vd = await ytVisitor();
        if (vd) { j = await ytPlayer(id, YT_CLIENTS[i], vd); st = j.playabilityStatus && j.playabilityStatus.status; plog.push(YT_CLIENTS[i].name + ': retried with visitor id -> ' + st); }
      }
      if (st === 'OK' && j.streamingData && (j.streamingData.adaptiveFormats || j.streamingData.formats)) {
        var fl = (j.streamingData.adaptiveFormats || []).concat(j.streamingData.formats || []).filter(function (f) { return f.url; });
        if (fl.length) {
          j.__client = YT_CLIENTS[i];
          var pf = fl.filter(function (f) { return (f.mimeType || '').indexOf('audio/mp4') === 0; })[0] || fl[0];
          var ua = YT_CLIENTS[i].ua;
          var pr = await ytProbe(pf.url, { 'User-Agent': ua });
          var ps = pr.s;
          plog.push(YT_CLIENTS[i].name + ': player ok (' + (Date.now() - tp - pr.ms) + 'ms), probe ' + (ps || ('error: ' + pr.err)) + ' (' + pr.ms + 'ms) host ' + gvHost(pf.url).slice(0, 14));
          j.__probe = ps; if (ps === 200 || ps === 206) { d = j; break; }
          if (ps) allErr = false;
          if (!diagDone && !ps) {
            diagDone = true;
            var rd = pf.url.replace(/^https:\/\/[^\/]+/, 'https://redirector.googlevideo.com');
            var rs = await Promise.all([rawProbe(pf.url, { family: '4', ua: ua }), rawProbe(pf.url, { family: '6', ua: ua }), rawProbe(pf.url, { family: 'any', range: false, ua: ua }),
              rawProbe(pf.url, { family: 'cell', ua: ua }), rawProbe(rd, { family: 'any', ua: ua }), ytProbe(rd, { 'User-Agent': ua })]);
            plog.push('raw ' + [rawDesc('IPv4', rs[0]), rawDesc('IPv6', rs[1]), rawDesc('GET no range', rs[2]), rawDesc('mobile data', rs[3]), rawDesc('redirector raw', rs[4])].join(', ') + ', redirector via URLSession: ' + (rs[5].s || ('error ' + rs[5].err)) + ' (' + rs[5].ms + 'ms)');
            if (rs[5].s === 200 || rs[5].s === 206) {
              // the cache node does not answer but the generic Google host does: use it for every stream
              [j.streamingData.adaptiveFormats || [], j.streamingData.formats || []].forEach(function (arr) { arr.forEach(function (f) { if (f.url) f.url = f.url.replace(/^https:\/\/[^\/]+/, 'https://redirector.googlevideo.com'); }); });
              j.__probe = rs[5].s; j.__redir = true; d = j; break;
            }
          }
          cands.push(j); lastReason = 'the stream was refused (HTTP ' + ps + ') with the ' + YT_CLIENTS[i].name + ' client';
          continue;
        }
      }
      lastReason = (j.playabilityStatus && (j.playabilityStatus.reason || st)) || 'unavailable';
      plog.push(YT_CLIENTS[i].name + ': ' + String(st || 'no streams') + ' (' + (Date.now() - tp) + 'ms)');
    } catch (e) { lastReason = String(e.message || e); plog.push(YT_CLIENTS[i].name + ': ' + String(e.message || e).slice(0, 60) + ' (' + (Date.now() - tp) + 'ms)'); }
  }
  if (!d && cands.length && allErr) {
    throw new Error('YouTube is blocking this connection: the video server does not answer from your network. Try mobile data or a VPN. [' + plog.join(' | ') + ']');
  }
  if (!d && cands.length) d = cands[0];
  if (!d) throw new Error('YouTube: ' + lastReason);
  var probeStatus = d.__probe || 0;
  var vd = d.videoDetails || {};
  var thumbs = (vd.thumbnail && vd.thumbnail.thumbnails) || [];
  var out = { title: vd.title || 'YouTube video', uploader: vd.author || '', duration: parseInt(vd.lengthSeconds || '0', 10),
    thumb: thumbs.length ? thumbs[thumbs.length - 1].url : ('https://i.ytimg.com/vi/' + id + '/hqdefault.jpg'), formats: [] };
  var hdr = { 'User-Agent': d.__client.ua };
  var all = (d.streamingData.adaptiveFormats || []).concat(d.streamingData.formats || []);
  var bestAudio = null;
  all.forEach(function (f) {
    if (!f.url) return;
    var mt = f.mimeType || '';
    if (mt.indexOf('audio/mp4') === 0) {
      var br = f.bitrate || 0;
      if (!bestAudio || br > bestAudio.bitrate || (f.itag === 140 && bestAudio.bitrate <= br)) bestAudio = f;
    }
  });
  if (bestAudio) out.formats.push({ id: 'a' + bestAudio.itag, kind: 'audio', label: 'M4A', detail: 'AAC audio', ext: 'm4a', size: parseInt(bestAudio.contentLength || '0', 10), url: bestAudio.url, headers: hdr, chunk: 8000000 });
  var seen = {};
  all.forEach(function (f) {
    if (!f.url) return;
    var mt = f.mimeType || '';
    if (mt.indexOf('video/mp4') !== 0 || mt.indexOf('avc1') < 0) return;
    var h = f.height || 0, key = h + (f.audioQuality ? 'm' : 'v');
    if (seen[key]) return; seen[key] = 1;
    var fps = f.fps && f.fps > 30 ? (' ' + f.fps + 'fps') : '';
    if (f.audioQuality) {
      out.formats.push({ id: 'm' + f.itag, kind: 'muxed', label: h + 'p' + fps, detail: 'MP4', ext: 'mp4', height: h, size: parseInt(f.contentLength || '0', 10), url: f.url, headers: hdr, chunk: 8000000 });
    } else if (bestAudio) {
      var sz = parseInt(f.contentLength || '0', 10) + parseInt(bestAudio.contentLength || '0', 10);
      out.formats.push({ id: 'v' + f.itag, kind: 'video', label: h + 'p' + fps, detail: 'MP4 (H.264 + AAC)', ext: 'mp4', height: h, size: sz, url: f.url, headers: hdr, chunk: 8000000,
        audio: { url: bestAudio.url, size: parseInt(bestAudio.contentLength || '0', 10), headers: hdr, chunk: 8000000 } });
    }
  });
  var hi = 0;
  all.forEach(function (f) { if ((f.height || 0) > hi) hi = f.height; });
  out.note = hi > 1080 ? ('Higher qualities up to ' + hi + 'p exist but use VP9/AV1, which iPhone cannot play. Flow offers up to 1080p.') : '';
  out.formats.forEach(function (f) { f.client = d.__client.name; f.probe = probeStatus; f.probelog = plog.join(' | '); });
  if (!out.formats.length) throw new Error('YouTube: no playable MP4 formats were returned');
  return out;
}

// ---------- X / Twitter ----------
function tweetId(u) { var m = u.match(/status(?:es)?\/(\d+)/); return m ? m[1] : null; }
async function twitter(url) {
  var id = tweetId(url);
  if (!id) throw new Error('Could not find the post id in this link');
  var token = ((Number(id) / 1e15) * Math.PI).toString(36).replace(/(0+|\.)/g, '');
  var r = await http({ url: 'https://cdn.syndication.twimg.com/tweet-result?id=' + id + '&lang=en&token=' + token, headers: { 'User-Agent': UA_DESK } });
  if (r.status !== 200) throw new Error('X: the post is not public or not available (HTTP ' + r.status + ')');
  var t = JSON.parse(r.text);
  var media = (t.mediaDetails || []).filter(function (m) { return m.video_info; });
  if (!media.length) {
    var photos = (t.mediaDetails || []).filter(function (m) { return m.type === 'photo'; });
    if (!photos.length) throw new Error('X: this post has no video');
    var o = { title: (t.text || 'X post').slice(0, 80), uploader: (t.user && t.user.name) || '', thumb: photos[0].media_url_https, duration: 0, formats: [] };
    photos.forEach(function (p, i) { o.formats.push({ id: 'p' + i, kind: 'muxed', label: 'Photo ' + (i + 1), detail: 'Original', ext: 'jpg', size: 0, url: p.media_url_https + (p.media_url_https.indexOf('?') < 0 ? '?name=orig' : ''), headers: {} }); });
    return o;
  }
  var m = media[0];
  var out = { title: (t.text || 'X video').replace(/https:\/\/t\.co\/\w+/g, '').trim().slice(0, 80) || 'X video', uploader: (t.user && t.user.name) || '',
    thumb: m.media_url_https, duration: Math.round(((m.video_info.duration_millis) || 0) / 1000), formats: [] };
  m.video_info.variants.filter(function (v) { return v.content_type === 'video/mp4'; }).sort(function (a, b) { return (b.bitrate || 0) - (a.bitrate || 0); }).forEach(function (v) {
    var hm = v.url.match(/\/(\d+)x(\d+)\//);
    out.formats.push({ id: 'x' + (v.bitrate || 0), kind: 'muxed', label: hm ? (Math.min(hm[1], hm[2]) + 'p') : 'MP4', detail: 'MP4', ext: 'mp4', height: hm ? Math.min(hm[1], hm[2]) : 0, size: 0, url: v.url, headers: {} });
  });
  if (!out.formats.length) throw new Error('X: no MP4 variants found');
  return out;
}


// Read size and real resolution of an MP4 URL with one small ranged request (size from Content-Range, size of picture from the tkhd box).
async function probeMp4(url, headers) {
  try {
    var r = await http({ url: url, timeout: 7, headers: Object.assign({ Range: 'bytes=0-98303' }, headers || {}) });
    var out = { size: 0, w: 0, h: 0 };
    var cr = r.headers && (r.headers['Content-Range'] || r.headers['content-range']);
    var m = cr && String(cr).match(/\/(\d+)\s*$/);
    if (m) out.size = parseInt(m[1], 10);
    else if (r.status === 200 && r.headers) { var cl = r.headers['Content-Length'] || r.headers['content-length']; if (cl) out.size = parseInt(cl, 10) || 0; }
    var t = r.text || '', i = -1;
    while ((i = t.indexOf('tkhd', i + 1)) >= 0) {
      var v = t.charCodeAt(i + 4) & 255, off = i + 4 + (v === 1 ? 88 : 76);
      var w = ((t.charCodeAt(off) & 255) << 8) | (t.charCodeAt(off + 1) & 255), hh = ((t.charCodeAt(off + 4) & 255) << 8) | (t.charCodeAt(off + 5) & 255);
      if (w > 0 && hh > 0 && w < 10000 && hh < 10000) { out.w = w; out.h = hh; break; }
    }
    return out;
  } catch (e) { return { size: 0, w: 0, h: 0 }; }
}
// Fill in size and a label that matches the real picture size. Never calls something HD that is not.
async function fillSizes(formats) {
  await Promise.all(formats.map(async function (f) {
    if (f.audio && f.audio.url && !f.size) {
      var pv = await probeMp4(f.url, f.headers), pa = await probeMp4(f.audio.url, f.audio.headers || f.headers);
      if (pv.size && pa.size) { f.size = pv.size + pa.size; f.audio.size = pa.size; if (pv.w && pv.h) f.detail = (f.detail || 'MP4') + ' \u00b7 ' + pv.w + '\u00d7' + pv.h; }
      return;
    }
    if (f.size || f.audio || f.kind === 'audio' || f.ext !== 'mp4' || !f.url) return;
    var p = await probeMp4(f.url, f.headers);
    if (p.size) f.size = p.size;
    if (p.w && p.h) {
      var q = Math.min(p.w, p.h);
      f.height = q; f.dims = p.w + 'x' + p.h;
      f.detail = (f.detail || 'MP4') + ' \u00b7 ' + p.w + '\u00d7' + p.h;
      f.label = q + 'p';
    }
  }));
  var seenL = {};
  formats.forEach(function (f) { if (f.kind !== 'audio') { var k = f.label; if (seenL[k]) f.label = k + ' (' + (f.id || '') + ')'; seenL[k] = 1; } });
}

// ---------- Facebook ----------
async function facebook(url) {
  var u = url.replace(/^https?:\/\/(www\.|m\.|web\.|mbasic\.)?(facebook|fb)\.com/i, 'https://www.facebook.com');
  var vid = (u.match(/\/reel\/(\d+)/) || u.match(/\/videos\/(?:[^\/]+\/)?(\d+)/) || u.match(/[?&]v=(\d+)/) || u.match(/\/watch\/?\?.*?v=(\d+)/) || [])[1];
  var H = function (ua) { return { 'User-Agent': ua, 'Accept-Language': 'en-US,en;q=0.9' }; };
  var tries = [{ url: u, headers: H(UA_DESK) }, { url: u.replace('www.facebook.com', 'm.facebook.com'), headers: H(UA_IOS) }];
  if (vid) {
    tries.push({ url: 'https://www.facebook.com/watch/?v=' + vid, headers: H(UA_DESK) });
    tries.push({ url: 'https://m.facebook.com/watch/?v=' + vid, headers: H(UA_IOS) });
    tries.push({ url: 'https://www.facebook.com/video/embed?video_id=' + vid, headers: H(UA_DESK) });
    tries.push({ url: 'https://mbasic.facebook.com/video.php?v=' + vid, headers: H(UA_IOS) });
  }
  tries.push({ url: 'https://www.facebook.com/plugins/video.php?show_text=false&href=' + encodeURIComponent(u), headers: H(UA_DESK) });
  var hd = null, sd = null, html = '', dashV = [], dashA = null, log = [];
  for (var i = 0; i < tries.length && !(hd && dashA); i++) {
    var r0 = null;
    try { r0 = await http(tries[i]); } catch (e) { log.push('x'); continue; }
    var h0 = r0.text || '';
    var g = fbCollect(h0);
    log.push((g.hd ? 'H' : '-') + (g.sd ? 'S' : '-') + (g.v.length ? 'D' : '-') + (g.a ? 'A' : '-'));
    if (g.hd && !hd) hd = g.hd;
    if (g.sd && !sd) sd = g.sd;
    if (g.v.length > dashV.length) dashV = g.v;
    if (g.a && !dashA) dashA = g.a;
    if (!sd && !hd) { var ogv = h0.match(/<meta property="og:video(?::secure_url)?" content="([^"]+)"/); if (ogv) sd = fixEsc(ogv[1]); }
    if (!html || (/og:title/.test(h0) && !/og:title/.test(html))) html = h0;
  }
  if (!hd && !sd && !dashV.length) throw new Error('Facebook: no public video was found at this link. Private videos, or ones needing login, are not supported.');
  var t = html.match(/<meta property="og:title" content="([^"]*)"/);
  var th = html.match(/<meta property="og:image" content="([^"]+)"/);
  var out = { title: t ? decodeEnt(fixEsc(t[1])) : 'Facebook video', uploader: '', thumb: th ? fixEsc(th[1]) : '', duration: 0, formats: [] };
  var h = { 'User-Agent': UA_DESK, 'Referer': 'https://www.facebook.com/' };
  var haveH = {};
  if (dashA) dashV.forEach(function (v) {
    if (haveH[v.h]) return; haveH[v.h] = 1;
    out.formats.push({ id: 'fd' + v.h, kind: 'video', label: v.h + 'p', detail: 'MP4 (video + audio)', ext: 'mp4', height: v.h, size: 0, url: v.url, headers: h, audio: { url: dashA, size: 0, headers: h } });
  });
  var topH = 0; dashV.forEach(function (v) { if (v.h > topH) topH = v.h; });
  if (hd && !(topH >= 720 && dashA)) out.formats.push({ id: 'fhd', kind: 'muxed', label: 'HD', detail: 'MP4', ext: 'mp4', size: 0, url: hd, headers: h });
  if (sd && sd !== hd) out.formats.push({ id: 'fsd', kind: 'muxed', label: 'SD', detail: 'MP4', ext: 'mp4', size: 0, url: sd, headers: h });
  if (!sd && !hd && !dashA) { var best = dashV.slice().sort(function (x, y) { return y.h - x.h; })[0]; out.formats.push({ id: 'fd', kind: 'muxed', label: best.h + 'p', detail: 'MP4 (no sound)', ext: 'mp4', size: 0, url: best.url, headers: h }); }
  var audSrc = sd || hd || (dashV[0] && dashV[0].url);
  if (dashA) out.formats.push({ id: 'faud', kind: 'audio', label: 'Audio', detail: 'M4A', ext: 'm4a', size: 0, url: dashA, headers: h });
  else if (audSrc) out.formats.push({ id: 'faud', kind: 'audio', label: 'Audio', detail: 'M4A (taken from the video)', ext: 'm4a', size: 0, url: audSrc, headers: h, extractAudio: true });
  await fillSizes(out.formats);
  var aud = out.formats.filter(function (f) { return f.kind === 'audio'; })[0];
  if (aud && aud.extractAudio) { var src = out.formats.filter(function (f) { return f.url === aud.url && f.kind !== 'audio'; })[0]; if (src && src.size) aud.size = Math.round(src.size * 0.12); }
  out.sources = log.join(',');
  return out;
}
function fbCollect(html) {
  var res = { hd: null, sd: null, v: [], a: null };
  res.hd = fbGrab(html, ['browser_native_hd_url', 'playable_url_quality_hd', 'hd_src', 'hd_src_no_ratelimit']);
  res.sd = fbGrab(html, ['browser_native_sd_url', 'playable_url', 'sd_src', 'sd_src_no_ratelimit']);
  var re = /"progressive_url"\s*:\s*"([^"]+)"[^{}]*?(?:\{[^{}]*?"quality"\s*:\s*"(HD|SD)")/g, m;
  while ((m = re.exec(html))) { if (m[2] === 'HD' && !res.hd) res.hd = fixEsc(m[1]); if (m[2] === 'SD' && !res.sd) res.sd = fixEsc(m[1]); }
  // DASH representations in JSON: look around each base_url
  var re2 = /"base_url"\s*:\s*"([^"]+)"/g, seen = {}, bestA = null;
  while ((m = re2.exec(html))) {
    var u = fixEsc(m[1]); if (seen[u]) continue; seen[u] = 1;
    var ws = html.lastIndexOf('{', m.index), we = html.indexOf('}', m.index);
    var w = html.slice(ws < 0 ? Math.max(0, m.index - 600) : ws, we < 0 ? m.index + 600 : we);
    var mime = (w.match(/"mime_type"\s*:\s*"([^"]+)"/) || [])[1] || '';
    var codecs = (w.match(/"codecs"\s*:\s*"([^"]+)"/) || [])[1] || '';
    var hh = parseInt((w.match(/"height"\s*:\s*(\d+)/) || [])[1] || '0', 10);
    var bw = parseInt((w.match(/"bandwidth"\s*:\s*(\d+)/) || [])[1] || '0', 10);
    if (!mime && /\.mp4/.test(u) && !hh) continue;
    if (mime.indexOf('audio') === 0 || (!hh && /mp4a/.test(codecs))) { if (!bestA || bw > bestA.bw) bestA = { url: u, bw: bw }; }
    else if (mime.indexOf('video') === 0 && hh && (!codecs || codecs.indexOf('avc1') === 0)) res.v.push({ url: u, h: hh, bw: bw });
  }
  // DASH manifest XML (escaped inside JSON)
  var mm = html.match(/"dash_manifest"\s*:\s*"((?:[^"\\]|\\.)*)"/);
  if (mm && !res.v.length) {
    var xml = fixEsc(mm[1]).replace(/\\\//g, '/');
    var re3 = /<Representation\b([^>]*)>[\s\S]*?<BaseURL>([^<]+)<\/BaseURL>/g;
    while ((m = re3.exec(xml))) {
      var at = m[1], url = decodeEnt(m[2]);
      var mt = (at.match(/mimeType="([^"]+)"/) || [])[1] || '', cd = (at.match(/codecs="([^"]+)"/) || [])[1] || '';
      var h3 = parseInt((at.match(/height="(\d+)"/) || [])[1] || '0', 10), b3 = parseInt((at.match(/bandwidth="(\d+)"/) || [])[1] || '0', 10);
      if (/audio/.test(mt) || /^mp4a/.test(cd)) { if (!bestA || b3 > bestA.bw) bestA = { url: url, bw: b3 }; }
      else if (h3 && (!cd || cd.indexOf('avc1') === 0)) res.v.push({ url: url, h: h3, bw: b3 });
    }
  }
  res.v.sort(function (x, y) { return y.h - x.h || y.bw - x.bw; });
  res.a = bestA ? bestA.url : null;
  return res;
}
function fbGrab(html, keys) {
  for (var i = 0; i < keys.length; i++) {
    var m = html.match(new RegExp('"' + keys[i] + '"\\s*:\\s*"([^"]+)"'));
    if (m) return fixEsc(m[1]);
  }
  return null;
}
function decodeEnt(s) {
  return s.replace(/&#x([0-9a-f]+);/gi, function (m, h) { return String.fromCharCode(parseInt(h, 16)); }).replace(/&#(\d+);/g, function (m, d) { return String.fromCharCode(parseInt(d, 10)); })
          .replace(/&quot;/g, '"').replace(/&apos;/g, "'").replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&amp;/g, '&');
}

// ---------- Instagram ----------
function igCode(u) { var m = u.match(/instagram\.com\/(?:[A-Za-z0-9_.]+\/)?(?:p|reel|reels|tv)\/([A-Za-z0-9_-]+)/); return m ? m[1] : null; }
async function instagram(url) {
  var code = igCode(url);
  if (!code) throw new Error('Instagram: paste a link to a post or reel');
  var r = await http({ url: 'https://www.instagram.com/p/' + code + '/embed/captioned/', headers: { 'User-Agent': UA_IOS, 'Accept-Language': 'en-US,en;q=0.9' } });
  var html = r.text || '';
  var vu = null;
  var m = html.match(/"video_url"\s*:\s*"([^"]+)"/);
  if (m) vu = fixEsc(m[1]);
  if (!vu) { m = html.match(/<video[^>]+src="([^"]+)"/); if (m) vu = fixEsc(m[1]); }
  var th = html.match(/"display_url"\s*:\s*"([^"]+)"/) || html.match(/class="EmbeddedMediaImage"[^>]+src="([^"]+)"/);
  var cap = html.match(/class="Caption"[\s\S]*?<\/a>([\s\S]*?)<div/);
  var title = cap ? cap[1].replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim().slice(0, 80) : '';
  if (!vu) {
    var j = html.match(/"contextJSON"\s*:\s*"((?:[^"\\]|\\.)*)"/);
    if (j) { try { var o = JSON.parse(JSON.parse('"' + j[1] + '"')); var sm = o.gql_data && o.gql_data.shortcode_media; if (sm) { vu = sm.video_url; if (!title && sm.edge_media_to_caption.edges[0]) title = sm.edge_media_to_caption.edges[0].node.text.slice(0, 80); } } catch (e) {} }
  }
  if (!vu) throw new Error('Instagram: no public video was found. Private accounts, or posts that need login, are not supported.');
  var h = { 'User-Agent': UA_IOS, 'Referer': 'https://www.instagram.com/' };
  var res = { title: decodeEnt(title || ('Instagram ' + code)), uploader: '', thumb: th ? fixEsc(th[1]) : '', duration: 0,
    formats: [{ id: 'ig', kind: 'muxed', label: 'Video', detail: 'MP4', ext: 'mp4', size: 0, url: vu, headers: h }] };
  await fillSizes(res.formats);
  res.note = 'Instagram gives one video quality for public posts.';
  return res;
}

// ---------- TikTok ----------
async function tiktok(url) {
  var r = await http({ url: url, headers: { 'User-Agent': UA_DESK, 'Accept-Language': 'en-US,en;q=0.9' } });
  var html = r.text || '';
  var m = html.match(/<script id="__UNIVERSAL_DATA_FOR_REHYDRATION__"[^>]*>([\s\S]*?)<\/script>/);
  if (!m) m = html.match(/<script id="SIGI_STATE"[^>]*>([\s\S]*?)<\/script>/);
  if (!m) throw new Error('TikTok: could not read the page. Try again, or open the video and copy its link again.');
  var data = JSON.parse(m[1]);
  var item = null;
  var scope = data['__DEFAULT_SCOPE__'];
  if (scope && scope['webapp.video-detail']) item = scope['webapp.video-detail'].itemInfo && scope['webapp.video-detail'].itemInfo.itemStruct;
  if (!item && data.ItemModule) { var k = Object.keys(data.ItemModule)[0]; item = data.ItemModule[k]; }
  if (!item || !item.video) throw new Error('TikTok: this video is not available publicly.');
  var v = item.video;
  var h = { 'User-Agent': UA_DESK, 'Referer': 'https://www.tiktok.com/' };
  var out = { title: decodeEnt(item.desc || 'TikTok video').slice(0, 80), uploader: (item.author && (item.author.nickname || item.author)) || '', thumb: v.cover || v.originCover || '', duration: v.duration || 0, formats: [] };
  var seen = {}, list = [];
  (v.bitrateInfo || []).forEach(function (b) {
    var u = b.PlayAddr && b.PlayAddr.UrlList && b.PlayAddr.UrlList[0];
    if (!u) return;
    var codec = (b.CodecType || '').indexOf('h265') >= 0 || (b.CodecType || '').indexOf('hvc') >= 0 ? 'H.265' : 'H.264';
    var ht = parseInt(b.PlayAddr.Height || 0, 10), wd = parseInt(b.PlayAddr.Width || 0, 10);
    var p = Math.min(ht || v.height || 0, wd || v.width || 9999) || 0;
    var key = p + codec; if (seen[key]) return; seen[key] = 1;
    list.push({ p: p, codec: codec, u: u, size: parseInt(b.PlayAddr.DataSize || '0', 10) });
  });
  list.sort(function (x, y) { return y.p - x.p || (x.codec === 'H.264' ? -1 : 1); });
  var used = {};
  list.forEach(function (x) {
    used[x.u] = 1;
    out.formats.push({ id: 't' + x.p + x.codec, kind: 'muxed', label: x.p ? x.p + 'p' : 'Video', detail: 'MP4 · ' + x.codec + (x.codec === 'H.264' ? ' (most compatible)' : ''), ext: 'mp4', height: x.p, size: x.size, url: x.u, headers: h });
  });
  if (v.playAddr && !used[v.playAddr]) { used[v.playAddr] = 1; out.formats.push({ id: 'tplay', kind: 'muxed', label: 'Standard', detail: 'MP4 · no watermark (if the site offers it)', ext: 'mp4', size: 0, url: v.playAddr, headers: h }); }
  if (v.downloadAddr && !used[v.downloadAddr]) out.formats.push({ id: 'tdl', kind: 'muxed', label: 'Original', detail: 'MP4 · may include the TikTok watermark', ext: 'mp4', size: 0, url: v.downloadAddr, headers: h });
  if (item.music && item.music.playUrl) out.formats.push({ id: 'tmusic', kind: 'audio', label: 'Sound', detail: 'Original sound (M4A/MP3)', ext: (item.music.playUrl.indexOf('.mp3') > 0 ? 'mp3' : 'm4a'), size: 0, url: item.music.playUrl, headers: h });
  if (!out.formats.length) throw new Error('TikTok: no downloadable video found');
  return out;
}

async function resolveShort(url) {
  // follow short links (vm.tiktok.com, fb.watch, t.co style) to the final URL
  var r = await http({ url: url, headers: { 'User-Agent': UA_DESK } });
  return r.url || url;
}

async function flowExtract(url) {
  var host = (url.match(/^https?:\/\/([^\/?#]+)/i) || [])[1];
  if (!host) throw new Error('That does not look like a link.');
  host = host.toLowerCase();
  if (/(^|\.)(youtube\.com|youtu\.be|youtube-nocookie\.com)$/.test(host)) return youtube(url);
  if (/(^|\.)(twitter\.com|x\.com|t\.co)$/.test(host)) { if (host === 't.co') url = await resolveShort(url); return twitter(url); }
  if (/(^|\.)(facebook\.com|fb\.watch|fb\.com)$/.test(host)) { if (host === 'fb.watch') url = await resolveShort(url); return facebook(url); }
  if (/(^|\.)instagram\.com$/.test(host)) return instagram(url);
  if (/(^|\.)tiktok\.com$/.test(host)) { if (/^(vm|vt)\./.test(host)) url = await resolveShort(url); return tiktok(url); }
  return null; // not a supported site: caller downloads the link directly
}
