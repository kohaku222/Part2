import { useEffect, useRef, useState } from 'react';
import { motion } from 'framer-motion';
import { Play, Pause, Sun, Check } from 'lucide-react';
import { Button } from '@/components/ui/button';

interface MotivationPlaybackProps {
  audioUrl: string;
  onComplete: () => void;
}

export function MotivationPlayback({ audioUrl, onComplete }: MotivationPlaybackProps) {
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [progress, setProgress] = useState(0);
  const [hasPlayed, setHasPlayed] = useState(false);

  useEffect(() => {
    if (audioRef.current) {
      // Auto-play after a short delay
      const timer = setTimeout(() => {
        audioRef.current?.play();
        setIsPlaying(true);
      }, 1000);

      audioRef.current.ontimeupdate = () => {
        if (audioRef.current) {
          const prog = (audioRef.current.currentTime / audioRef.current.duration) * 100;
          setProgress(prog);
        }
      };

      audioRef.current.onended = () => {
        setIsPlaying(false);
        setHasPlayed(true);
      };

      return () => clearTimeout(timer);
    }
  }, [audioUrl]);

  const togglePlayback = () => {
    if (!audioRef.current) return;

    if (isPlaying) {
      audioRef.current.pause();
    } else {
      audioRef.current.play();
    }
    setIsPlaying(!isPlaying);
  };

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      className="min-h-screen flex flex-col items-center justify-center p-6"
    >
      {/* Sunrise animation */}
      <motion.div
        initial={{ y: 100, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ duration: 1.5, ease: 'easeOut' }}
        className="absolute inset-x-0 bottom-0 h-1/2 pointer-events-none"
        style={{
          background: 'linear-gradient(to top, hsl(35 90% 55% / 0.2) 0%, transparent 100%)',
        }}
      />

      <motion.div
        initial={{ scale: 0 }}
        animate={{ scale: 1 }}
        transition={{ delay: 0.5, type: 'spring' }}
        className="p-8 rounded-full bg-primary/10 mb-8"
      >
        <Sun className="w-20 h-20 text-primary" />
      </motion.div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.8 }}
        className="text-center mb-8"
      >
        <h1 className="text-2xl font-semibold mb-2">おはようございます！</h1>
        <p className="text-muted-foreground">
          昨日のあなたからのメッセージです
        </p>
      </motion.div>

      {/* Audio player */}
      <motion.div
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ delay: 1 }}
        className="glass-card p-6 w-full max-w-sm space-y-4"
      >
        {/* Progress bar */}
        <div className="h-2 bg-muted rounded-full overflow-hidden">
          <motion.div
            className="h-full bg-primary"
            style={{ width: `${progress}%` }}
          />
        </div>

        {/* Waveform visualization */}
        <div className="flex items-center justify-center gap-1 h-16">
          {Array.from({ length: 30 }).map((_, i) => (
            <motion.div
              key={i}
              className="w-1 bg-primary/50 rounded-full"
              animate={isPlaying ? {
                height: ['20%', `${40 + Math.sin(i * 0.5) * 40}%`, '20%'],
              } : {
                height: '20%',
              }}
              transition={{
                duration: 0.5,
                repeat: isPlaying ? Infinity : 0,
                delay: i * 0.05,
              }}
            />
          ))}
        </div>

        {/* Controls */}
        <div className="flex justify-center">
          <Button
            variant="glow"
            size="icon-xl"
            onClick={togglePlayback}
            className="rounded-full"
          >
            {isPlaying ? (
              <Pause className="w-8 h-8" />
            ) : (
              <Play className="w-8 h-8 ml-1" />
            )}
          </Button>
        </div>
      </motion.div>

      <audio ref={audioRef} src={audioUrl} />

      {hasPlayed && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="mt-8"
        >
          <Button variant="default" size="lg" onClick={onComplete}>
            <Check className="w-5 h-5 mr-2" />
            今日も頑張ろう！
          </Button>
        </motion.div>
      )}
    </motion.div>
  );
}
