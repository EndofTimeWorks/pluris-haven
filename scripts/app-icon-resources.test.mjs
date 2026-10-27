import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';

const androidRoot = new URL('../mobile/android/app/src/main/', import.meta.url);
const iosRoot = new URL(
  '../mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/',
  import.meta.url,
);

async function pngHeader(url) {
  const data = await readFile(url);
  assert.deepEqual(
    data.subarray(0, 8),
    Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    `${url.pathname} is not a PNG`,
  );
  assert.equal(data.subarray(12, 16).toString('ascii'), 'IHDR');
  return {
    width: data.readUInt32BE(16),
    height: data.readUInt32BE(20),
    bitDepth: data[24],
    colorType: data[25],
  };
}

test('Android manifest and adaptive icon resources use the branded layers', async () => {
  const manifest = await readFile(new URL('AndroidManifest.xml', androidRoot), 'utf8');
  assert.match(manifest, /android:icon="@mipmap\/ic_launcher"/);
  assert.match(manifest, /android:roundIcon="@mipmap\/ic_launcher_round"/);

  const expectedLayers = [
    '<background android:drawable="@color/ic_launcher_background" />',
    '<foreground android:drawable="@mipmap/ic_launcher_foreground" />',
  ];
  for (const file of ['ic_launcher.xml', 'ic_launcher_round.xml']) {
    const xml = await readFile(new URL(`res/mipmap-anydpi-v26/${file}`, androidRoot), 'utf8');
    assert.match(xml, /<adaptive-icon /);
    for (const layer of expectedLayers) assert.ok(xml.includes(layer));
  }

  const colors = await readFile(new URL('res/values/colors.xml', androidRoot), 'utf8');
  assert.match(colors, /<color name="ic_launcher_background">#11062D<\/color>/);
});

test('Android icon bitmaps cover legacy and adaptive launcher densities', async () => {
  const densities = {
    mdpi: [48, 108],
    hdpi: [72, 162],
    xhdpi: [96, 216],
    xxhdpi: [144, 324],
    xxxhdpi: [192, 432],
  };

  for (const [density, [legacySide, adaptiveSide]] of Object.entries(densities)) {
    const resourceRoot = new URL(`res/mipmap-${density}/`, androidRoot);
    const legacy = await pngHeader(new URL('ic_launcher.png', resourceRoot));
    const round = await pngHeader(new URL('ic_launcher_round.png', resourceRoot));
    const foreground = await pngHeader(new URL('ic_launcher_foreground.png', resourceRoot));

    assert.deepEqual(legacy, {
      width: legacySide,
      height: legacySide,
      bitDepth: 8,
      colorType: 2,
    });
    assert.deepEqual(round, {
      width: legacySide,
      height: legacySide,
      bitDepth: 8,
      colorType: 6,
    });
    assert.deepEqual(foreground, {
      width: adaptiveSide,
      height: adaptiveSide,
      bitDepth: 8,
      colorType: 6,
    });
  }
});

test('iOS keeps an opaque square marketing icon for platform masking', async () => {
  const marketing = await pngHeader(new URL('Icon-App-1024x1024@1x.png', iosRoot));
  assert.deepEqual(marketing, {
    width: 1024,
    height: 1024,
    bitDepth: 8,
    colorType: 2,
  });

  const contents = JSON.parse(await readFile(new URL('Contents.json', iosRoot), 'utf8'));
  assert.ok(
    contents.images.some(
      (image) =>
        image.idiom === 'ios-marketing' &&
        image.size === '1024x1024' &&
        image.filename === 'Icon-App-1024x1024@1x.png',
    ),
  );
});
