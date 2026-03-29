import React from 'react';
import { Composition } from 'remotion';
import { CoralRSEVideo } from './CoralRSEVideo';

export const RemotionRoot: React.FC = () => {
  return (
    <Composition
      id="CoralRSE"
      component={CoralRSEVideo}
      durationInFrames={2730}
      fps={30}
      width={1920}
      height={1080}
    />
  );
};
