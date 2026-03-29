import React from 'react';
import { AbsoluteFill, Series } from 'remotion';
import { loadFont as loadCrimsonPro } from '@remotion/google-fonts/CrimsonPro';
import { loadFont as loadInter } from '@remotion/google-fonts/Inter';
import { loadFont as loadJetBrainsMono } from '@remotion/google-fonts/JetBrainsMono';
import { COLORS } from './styles';
import { SceneFade } from './components/SceneFade';
import { TitleScene } from './scenes/TitleScene';
import { ProblemScene } from './scenes/ProblemScene';
import { ExternalReefsScene } from './scenes/ExternalReefsScene';
import { LabPipelineScene } from './scenes/LabPipelineScene';
import { DecisionPointScene } from './scenes/DecisionPointScene';
import { OrchardGrowthScene } from './scenes/OrchardGrowthScene';
import { ReefOutplantingScene } from './scenes/ReefOutplantingScene';
import { TheCycleScene } from './scenes/TheCycleScene';
import { StochasticityScene } from './scenes/StochasticityScene';
import { DisturbanceScene } from './scenes/DisturbanceScene';
import { StrategyComparisonScene } from './scenes/StrategyComparisonScene';
import { SummaryScene } from './scenes/SummaryScene';

loadCrimsonPro('normal', { weights: ['400', '700'], subsets: ['latin'] });
loadInter('normal', { weights: ['400', '600', '700'], subsets: ['latin'] });
loadJetBrainsMono('normal', { weights: ['400', '700'], subsets: ['latin'] });

const FPS = 30;

export const CoralRSEVideo: React.FC = () => {
  return (
    <AbsoluteFill style={{ backgroundColor: COLORS.bg }}>
      <Series>
        <Series.Sequence durationInFrames={4 * FPS}>
          <SceneFade fadeInFrames={0} fadeOutFrames={15}>
            <TitleScene />
          </SceneFade>
        </Series.Sequence>
        <Series.Sequence durationInFrames={5 * FPS}>
          <SceneFade>
            <ProblemScene />
          </SceneFade>
        </Series.Sequence>
        <Series.Sequence durationInFrames={5 * FPS}>
          <SceneFade>
            <ExternalReefsScene />
          </SceneFade>
        </Series.Sequence>
        <Series.Sequence durationInFrames={10 * FPS}>
          <SceneFade>
            <LabPipelineScene />
          </SceneFade>
        </Series.Sequence>
        <Series.Sequence durationInFrames={5 * FPS}>
          <SceneFade>
            <DecisionPointScene />
          </SceneFade>
        </Series.Sequence>
        <Series.Sequence durationInFrames={10 * FPS}>
          <SceneFade>
            <OrchardGrowthScene />
          </SceneFade>
        </Series.Sequence>
        <Series.Sequence durationInFrames={10 * FPS}>
          <SceneFade>
            <ReefOutplantingScene />
          </SceneFade>
        </Series.Sequence>
        <Series.Sequence durationInFrames={10 * FPS}>
          <SceneFade>
            <TheCycleScene />
          </SceneFade>
        </Series.Sequence>
        <Series.Sequence durationInFrames={8 * FPS}>
          <SceneFade>
            <StochasticityScene />
          </SceneFade>
        </Series.Sequence>
        <Series.Sequence durationInFrames={8 * FPS}>
          <SceneFade>
            <DisturbanceScene />
          </SceneFade>
        </Series.Sequence>
        <Series.Sequence durationInFrames={10 * FPS}>
          <SceneFade>
            <StrategyComparisonScene />
          </SceneFade>
        </Series.Sequence>
        <Series.Sequence durationInFrames={6 * FPS}>
          <SceneFade fadeInFrames={15} fadeOutFrames={20}>
            <SummaryScene />
          </SceneFade>
        </Series.Sequence>
      </Series>
    </AbsoluteFill>
  );
};
