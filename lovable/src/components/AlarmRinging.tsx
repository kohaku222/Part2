import { useEffect, useRef, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Bell, QrCode, Volume2 } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { QRScanner } from './QRScanner';

interface AlarmRingingProps {
  alarmTime: string;
  registeredCode: string;
  onStop: () => void;
}

export function AlarmRinging({ alarmTime, registeredCode, onStop }: AlarmRingingProps) {
  const [showScanner, setShowScanner] = useState(false);
  const [isShaking, setIsShaking] = useState(true);
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const audioContextRef = useRef<AudioContext | null>(null);
  const oscillatorRef = useRef<OscillatorNode | null>(null);

  // Create alarm sound using Web Audio API
  useEffect(() => {
    const playAlarmSound = () => {
      try {
        const audioContext = new AudioContext();
        audioContextRef.current = audioContext;

        const playBeep = () => {
          if (!audioContextRef.current) return;
          
          const oscillator = audioContext.createOscillator();
          const gainNode = audioContext.createGain();
          
          oscillator.connect(gainNode);
          gainNode.connect(audioContext.destination);
          
          oscillator.frequency.value = 800;
          oscillator.type = 'sine';
          
          gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
          gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.5);
          
          oscillator.start(audioContext.currentTime);
          oscillator.stop(audioContext.currentTime + 0.5);
        };

        // Play beep pattern
        const interval = setInterval(() => {
          playBeep();
        }, 1000);

        return () => {
          clearInterval(interval);
          audioContext.close();
        };
      } catch (error) {
        console.error('Audio error:', error);
      }
    };

    const cleanup = playAlarmSound();
    
    return () => {
      cleanup?.();
      if (audioContextRef.current) {
        audioContextRef.current.close();
      }
    };
  }, []);

  const handleScanSuccess = (code: string) => {
    if (code === registeredCode) {
      // Stop the alarm
      if (audioContextRef.current) {
        audioContextRef.current.close();
      }
      onStop();
    }
  };

  if (showScanner) {
    return (
      <QRScanner
        onScan={handleScanSuccess}
        onBack={() => setShowScanner(false)}
        isSetup={false}
        registeredCode={registeredCode}
      />
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      className="min-h-screen flex flex-col items-center justify-center p-6 relative overflow-hidden"
    >
      {/* Background pulse effect */}
      <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
        <motion.div
          animate={{
            scale: [1, 1.5, 1],
            opacity: [0.3, 0.1, 0.3],
          }}
          transition={{
            duration: 2,
            repeat: Infinity,
            ease: 'easeInOut',
          }}
          className="w-80 h-80 rounded-full bg-primary/20"
        />
      </div>

      <motion.div
        animate={isShaking ? { x: [-4, 4, -4, 4, 0] } : {}}
        transition={{ duration: 0.4, repeat: Infinity }}
        className="relative z-10 flex flex-col items-center gap-8"
      >
        {/* Bell icon */}
        <motion.div
          animate={{ rotate: [-10, 10, -10] }}
          transition={{ duration: 0.2, repeat: Infinity }}
          className="p-6 rounded-full bg-primary/20 glow-primary"
        >
          <Bell className="w-16 h-16 text-primary" />
        </motion.div>

        {/* Time */}
        <div className="text-center">
          <p className="time-display text-6xl mb-2">{alarmTime}</p>
          <p className="text-muted-foreground">アラーム</p>
        </div>

        {/* Volume indicator */}
        <div className="flex items-center gap-2 text-muted-foreground">
          <Volume2 className="w-5 h-5" />
          <div className="flex gap-1">
            {[...Array(5)].map((_, i) => (
              <motion.div
                key={i}
                animate={{ opacity: [0.3, 1, 0.3] }}
                transition={{
                  duration: 0.5,
                  repeat: Infinity,
                  delay: i * 0.1,
                }}
                className="w-1 h-4 bg-primary rounded-full"
              />
            ))}
          </div>
        </div>

        {/* Scan button */}
        <Button
          variant="glow"
          size="xl"
          onClick={() => setShowScanner(true)}
          className="mt-8"
        >
          <QrCode className="w-5 h-5 mr-2" />
          スキャンして停止
        </Button>

        <p className="text-sm text-muted-foreground text-center max-w-xs">
          登録したQRコードをスキャンするまでアラームは止まりません
        </p>
      </motion.div>
    </motion.div>
  );
}
