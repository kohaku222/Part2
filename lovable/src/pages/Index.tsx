import { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus, Moon, Sparkles } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { TimeDisplay } from '@/components/TimeDisplay';
import { AlarmCard } from '@/components/AlarmCard';
import { SetAlarmDialog } from '@/components/SetAlarmDialog';
import { VoiceRecorder } from '@/components/VoiceRecorder';
import { QRScanner } from '@/components/QRScanner';
import { AlarmRinging } from '@/components/AlarmRinging';
import { MotivationPlayback } from '@/components/MotivationPlayback';
import { useAlarmStorage } from '@/hooks/useAlarmStorage';
import { AppView, Alarm } from '@/types/alarm';

const Index = () => {
  const [view, setView] = useState<AppView>('main');
  const { alarm, saveAlarm, updateAlarm, deleteAlarm } = useAlarmStorage();
  const [tempVoiceBlob, setTempVoiceBlob] = useState<Blob | null>(null);

  // Check if alarm should ring
  useEffect(() => {
    if (!alarm?.enabled) return;

    const checkAlarm = () => {
      const now = new Date();
      const currentTime = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;
      
      if (currentTime === alarm.time && alarm.qrCode) {
        setView('alarm-ringing');
      }
    };

    const interval = setInterval(checkAlarm, 1000);
    return () => clearInterval(interval);
  }, [alarm]);

  const handleCreateAlarm = (time: string) => {
    const newAlarm: Alarm = {
      id: Date.now().toString(),
      time,
      enabled: true,
    };
    saveAlarm(newAlarm);
    setView('main');
  };

  const handleSaveVoice = (blob: Blob, url: string) => {
    setTempVoiceBlob(blob);
    updateAlarm({ voiceRecording: blob, voiceRecordingUrl: url });
    setView('main');
  };

  const handleSaveQR = (code: string) => {
    updateAlarm({ qrCode: code });
    setView('main');
  };

  const handleAlarmStop = () => {
    if (alarm?.voiceRecordingUrl) {
      setView('motivation-playback');
    } else {
      setView('main');
    }
  };

  const handlePlaybackComplete = () => {
    updateAlarm({ enabled: false });
    setView('main');
  };

  const handleToggleAlarm = () => {
    if (alarm) {
      updateAlarm({ enabled: !alarm.enabled });
    }
  };

  return (
    <AnimatePresence mode="wait">
      {view === 'main' && (
        <motion.div
          key="main"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="min-h-screen flex flex-col p-6 pb-32"
        >
          {/* Header */}
          <header className="flex items-center justify-between mb-12">
            <div className="flex items-center gap-2">
              <Moon className="w-5 h-5 text-primary" />
              <span className="text-sm font-medium text-muted-foreground">
                モチベーション目覚まし
              </span>
            </div>
            <Sparkles className="w-5 h-5 text-accent" />
          </header>

          {/* Current time */}
          <div className="mb-12">
            <TimeDisplay size="xl" />
            <p className="text-center text-muted-foreground mt-4">
              {new Date().toLocaleDateString('ja-JP', {
                weekday: 'long',
                year: 'numeric',
                month: 'long',
                day: 'numeric',
              })}
            </p>
          </div>

          {/* Alarm list */}
          <div className="flex-1 space-y-4">
            {alarm ? (
              <AlarmCard
                alarm={alarm}
                onToggle={handleToggleAlarm}
                onDelete={deleteAlarm}
                onRecordVoice={() => setView('record-voice')}
                onSetupQR={() => setView('scan-setup')}
              />
            ) : (
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="glass-card p-8 text-center"
              >
                <Moon className="w-12 h-12 mx-auto text-muted-foreground mb-4" />
                <h2 className="text-lg font-medium mb-2">アラームがありません</h2>
                <p className="text-sm text-muted-foreground">
                  下のボタンから新しいアラームを作成しましょう
                </p>
              </motion.div>
            )}
          </div>

          {/* Add alarm button */}
          {!alarm && (
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="fixed bottom-8 left-1/2 -translate-x-1/2"
            >
              <Button
                variant="glow"
                size="icon-xl"
                onClick={() => setView('set-alarm')}
                className="rounded-full"
              >
                <Plus className="w-8 h-8" />
              </Button>
            </motion.div>
          )}
        </motion.div>
      )}

      {view === 'set-alarm' && (
        <SetAlarmDialog
          key="set-alarm"
          onSave={handleCreateAlarm}
          onBack={() => setView('main')}
          initialTime={alarm?.time}
        />
      )}

      {view === 'record-voice' && (
        <VoiceRecorder
          key="record-voice"
          onSave={handleSaveVoice}
          onBack={() => setView('main')}
          existingUrl={alarm?.voiceRecordingUrl}
        />
      )}

      {view === 'scan-setup' && (
        <QRScanner
          key="scan-setup"
          onScan={handleSaveQR}
          onBack={() => setView('main')}
          isSetup={true}
        />
      )}

      {view === 'alarm-ringing' && alarm && (
        <AlarmRinging
          key="alarm-ringing"
          alarmTime={alarm.time}
          registeredCode={alarm.qrCode || ''}
          onStop={handleAlarmStop}
        />
      )}

      {view === 'motivation-playback' && alarm?.voiceRecordingUrl && (
        <MotivationPlayback
          key="motivation-playback"
          audioUrl={alarm.voiceRecordingUrl}
          onComplete={handlePlaybackComplete}
        />
      )}
    </AnimatePresence>
  );
};

export default Index;
