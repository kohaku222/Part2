import { motion } from 'framer-motion';
import { Mic, Square, Play, Pause, RotateCcw, Check, ArrowLeft } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useAudioRecorder } from '@/hooks/useAudioRecorder';
import { useState, useRef, useEffect } from 'react';

interface VoiceRecorderProps {
  onSave: (blob: Blob, url: string) => void;
  onBack: () => void;
  existingUrl?: string;
}

export function VoiceRecorder({ onSave, onBack, existingUrl }: VoiceRecorderProps) {
  const {
    isRecording,
    audioBlob,
    audioUrl,
    duration,
    audioLevels,
    startRecording,
    stopRecording,
    clearRecording,
  } = useAudioRecorder();

  const [isPlaying, setIsPlaying] = useState(false);
  const audioRef = useRef<HTMLAudioElement | null>(null);

  const formatDuration = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const handlePlayPause = () => {
    if (!audioRef.current) return;
    
    if (isPlaying) {
      audioRef.current.pause();
    } else {
      audioRef.current.play();
    }
    setIsPlaying(!isPlaying);
  };

  const handleSave = () => {
    if (audioBlob && audioUrl) {
      onSave(audioBlob, audioUrl);
    }
  };

  useEffect(() => {
    if (audioRef.current) {
      audioRef.current.onended = () => setIsPlaying(false);
    }
  }, [audioUrl]);

  const currentUrl = audioUrl || existingUrl;

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      className="min-h-screen flex flex-col p-6"
    >
      <div className="flex items-center gap-4 mb-8">
        <Button variant="ghost" size="icon" onClick={onBack}>
          <ArrowLeft className="w-5 h-5" />
        </Button>
        <h1 className="text-xl font-semibold">モチベーション録音</h1>
      </div>

      <div className="flex-1 flex flex-col items-center justify-center gap-8">
        <div className="text-center space-y-2">
          <p className="text-muted-foreground">
            明日の自分へのメッセージを録音しましょう
          </p>
          <p className="text-sm text-muted-foreground/70">
            目標、やる気、前向きな言葉を残してください
          </p>
        </div>

        {/* Visualizer */}
        <div className="w-full max-w-md h-32 flex items-center justify-center gap-1 px-4">
          {isRecording ? (
            audioLevels.map((level, index) => (
              <motion.div
                key={index}
                className="w-2 bg-primary rounded-full"
                animate={{ height: `${Math.max(8, level * 100)}%` }}
                transition={{ duration: 0.05 }}
              />
            ))
          ) : currentUrl ? (
            <div className="flex items-center gap-1">
              {Array.from({ length: 20 }).map((_, i) => (
                <div
                  key={i}
                  className="w-2 bg-primary/30 rounded-full"
                  style={{ height: `${20 + Math.sin(i * 0.5) * 30}%` }}
                />
              ))}
            </div>
          ) : (
            <div className="flex items-center gap-1">
              {Array.from({ length: 20 }).map((_, i) => (
                <div
                  key={i}
                  className="w-2 bg-muted rounded-full h-2"
                />
              ))}
            </div>
          )}
        </div>

        {/* Timer */}
        <div className="font-mono text-4xl text-primary">
          {formatDuration(duration)}
        </div>

        {/* Controls */}
        <div className="flex items-center gap-4">
          {!isRecording && !currentUrl && (
            <Button
              variant="glow"
              size="icon-xl"
              onClick={startRecording}
              className="rounded-full"
            >
              <Mic className="w-8 h-8" />
            </Button>
          )}

          {isRecording && (
            <Button
              variant="recording"
              size="icon-xl"
              onClick={stopRecording}
              className="rounded-full"
            >
              <Square className="w-8 h-8" />
            </Button>
          )}

          {currentUrl && !isRecording && (
            <>
              <Button
                variant="outline"
                size="icon-lg"
                onClick={clearRecording}
                className="rounded-full"
              >
                <RotateCcw className="w-6 h-6" />
              </Button>

              <Button
                variant="glass"
                size="icon-xl"
                onClick={handlePlayPause}
                className="rounded-full"
              >
                {isPlaying ? (
                  <Pause className="w-8 h-8" />
                ) : (
                  <Play className="w-8 h-8 ml-1" />
                )}
              </Button>

              <Button
                variant="glow"
                size="icon-lg"
                onClick={handleSave}
                className="rounded-full"
              >
                <Check className="w-6 h-6" />
              </Button>
            </>
          )}
        </div>

        {currentUrl && (
          <audio ref={audioRef} src={currentUrl} />
        )}
      </div>

      {isRecording && (
        <p className="text-center text-sm text-muted-foreground animate-pulse">
          録音中... タップして停止
        </p>
      )}
    </motion.div>
  );
}
