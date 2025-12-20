import { useState } from 'react';
import { motion } from 'framer-motion';
import { ArrowLeft, Check } from 'lucide-react';
import { Button } from '@/components/ui/button';

interface SetAlarmDialogProps {
  onSave: (time: string) => void;
  onBack: () => void;
  initialTime?: string;
}

export function SetAlarmDialog({ onSave, onBack, initialTime }: SetAlarmDialogProps) {
  const [hours, setHours] = useState(() => {
    if (initialTime) return parseInt(initialTime.split(':')[0]);
    return 7;
  });
  const [minutes, setMinutes] = useState(() => {
    if (initialTime) return parseInt(initialTime.split(':')[1]);
    return 0;
  });

  const handleSave = () => {
    const time = `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`;
    onSave(time);
  };

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
        <h1 className="text-xl font-semibold">アラームを設定</h1>
      </div>

      <div className="flex-1 flex flex-col items-center justify-center gap-8">
        {/* Time picker */}
        <div className="flex items-center gap-4">
          {/* Hours */}
          <div className="flex flex-col items-center">
            <Button
              variant="ghost"
              size="icon"
              onClick={() => setHours((h) => (h + 1) % 24)}
              className="text-2xl"
            >
              ▲
            </Button>
            <div className="time-display text-7xl py-4 w-32 text-center">
              {hours.toString().padStart(2, '0')}
            </div>
            <Button
              variant="ghost"
              size="icon"
              onClick={() => setHours((h) => (h - 1 + 24) % 24)}
              className="text-2xl"
            >
              ▼
            </Button>
          </div>

          <span className="time-display text-7xl">:</span>

          {/* Minutes */}
          <div className="flex flex-col items-center">
            <Button
              variant="ghost"
              size="icon"
              onClick={() => setMinutes((m) => (m + 5) % 60)}
              className="text-2xl"
            >
              ▲
            </Button>
            <div className="time-display text-7xl py-4 w-32 text-center">
              {minutes.toString().padStart(2, '0')}
            </div>
            <Button
              variant="ghost"
              size="icon"
              onClick={() => setMinutes((m) => (m - 5 + 60) % 60)}
              className="text-2xl"
            >
              ▼
            </Button>
          </div>
        </div>

        {/* Quick select */}
        <div className="flex gap-2 flex-wrap justify-center">
          {[
            { h: 6, m: 0 },
            { h: 6, m: 30 },
            { h: 7, m: 0 },
            { h: 7, m: 30 },
            { h: 8, m: 0 },
          ].map(({ h, m }) => (
            <Button
              key={`${h}:${m}`}
              variant={hours === h && minutes === m ? 'default' : 'outline'}
              size="sm"
              onClick={() => {
                setHours(h);
                setMinutes(m);
              }}
            >
              {h.toString().padStart(2, '0')}:{m.toString().padStart(2, '0')}
            </Button>
          ))}
        </div>
      </div>

      <Button variant="glow" size="xl" className="w-full" onClick={handleSave}>
        <Check className="w-5 h-5 mr-2" />
        保存
      </Button>
    </motion.div>
  );
}
