const esbuild = require('C:/Herramientas/Ajedrez Lyanna/node_modules/esbuild');
const fs = require('fs');
const path = require('path');

const entryPath = path.resolve(__dirname, 'temp_entry.ts');
const entryCode = `
import { CAMP_BASE_CURRICULUM, CAMP_BASE_LESSONS, CAMP_BASE_BIOME_META } from 'C:/Herramientas/Ajedrez Lyanna/src/data/campBaseContent';
import { LESSONS_CURRICULUM } from 'C:/Herramientas/Ajedrez Lyanna/src/data/lessonsContent';
import { BIOMES } from 'C:/Herramientas/Ajedrez Lyanna/src/data/curriculumPreview';

export { CAMP_BASE_CURRICULUM, CAMP_BASE_LESSONS, CAMP_BASE_BIOME_META, LESSONS_CURRICULUM, BIOMES };
`;

fs.writeFileSync(entryPath, entryCode, 'utf8');

try {
  const result = esbuild.buildSync({
    entryPoints: [entryPath],
    bundle: true,
    format: 'cjs',
    write: false,
    platform: 'node',
  });

  const bundledCode = result.outputFiles[0].text;
  const tempBundlePath = path.resolve(__dirname, 'temp_bundled.cjs');
  fs.writeFileSync(tempBundlePath, bundledCode, 'utf8');

  const data = require(tempBundlePath);
  
  // Combine biomes
  const biomes = [data.CAMP_BASE_BIOME_META, ...data.BIOMES];
  const curriculum = data.LESSONS_CURRICULUM;
  
  const lessonKeys = Object.keys(curriculum);
  console.log(`Successfully extracted ${lessonKeys.length} lessons from curriculum.`);
  console.log(`Total biomes: ${biomes.length}`);

  // Structure the final JSON cleanly
  const outputData = {
    total_lessons: lessonKeys.length,
    biomes: biomes.map(b => ({
      id: b.id,
      name: b.name,
      subtitle: b.subtitle,
      themeTag: b.themeTag,
      description: b.description,
      lessons: b.lessons ? b.lessons.map(l => ({
        id: l.id,
        code: l.code,
        title: l.title,
        subtitle: l.subtitle,
        type: l.type,
        icon: l.icon,
        rewardEmeralds: l.rewardEmeralds,
        durationMinutes: l.durationMinutes,
        pollitoIntro: l.pollitoIntro,
        skillsTrained: l.skillsTrained
      })) : []
    })),
    lessons: curriculum
  };

  const outputPath = 'C:/Herramientas/Ajedrez Lyanna Godot/ajedrez-de-pollito/data/lessons.json';
  fs.writeFileSync(outputPath, JSON.stringify(outputData, null, 2), 'utf8');
  console.log(`Wrote lessons.json to ${outputPath} (${(fs.statSync(outputPath).size / 1024).toFixed(1)} KB)`);

  // Clean up temp files
  if (fs.existsSync(entryPath)) fs.unlinkSync(entryPath);
  if (fs.existsSync(tempBundlePath)) fs.unlinkSync(tempBundlePath);

} catch (err) {
  console.error('Error during extraction:', err);
  process.exit(1);
}
