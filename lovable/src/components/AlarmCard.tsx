import { motion } from 'framer-motion';
import { Bell, Mic, QrCode, Trash2, Power } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Alarm } from '@/types/alarm';

interface AlarmCardProps {
  alarm: Alarm;
  onToggle: () => void;
  onDelete: () => void;
  onRecordVoice: () => void;
  onSetupQR: () => void;
}

export function AlarmCard({ alarm, onToggle, onDelete, onRecordVoice, onSetupQR }: AlarmCardProps) {
  const hasVoice = !!alarm.voiceRecordingUrl;
  const hasQR = !!alarm.qrCode;

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="glass-card p-6 space-y-4"
    >
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <div 
            className={`p-3 rounded-xl ${alarm.enabled ? 'bg-primary/20' : 'bg-muted'}`}
          >
            <Bell className={`w-6 h-6 ${alarm.enabled ? 'text-primary' : 'text-muted-foreground'}`} />
          </div>
          <div>
            <p className="time-display text-4xl">{alarm.time}</p>
            {alarm.label && (
              <p className="text-sm text-muted-foreground mt-1">{alarm.label}</p>
            )}
          </div>
        </div>
        
        <Button
          variant={alarm.enabled ? 'glow' : 'outline'}
          size="icon-lg"
          onClick={onToggle}
          className="rounded-full"
        >
          <Power className="w-6 h-6" />
        </Button>
      </div>

      <div className="flex gap-2">
        <Button
          variant={hasVoice ? 'default' : 'outline'}
          size="sm"
          onClick={onRecordVoice}
          className="flex-1"
        >
          <Mic className="w-4 h-4 mr-2" />
          {hasVoice ? '録音済み' : '声を録音'}
        </Button>
        
        <Button
          variant={hasQR ? 'default' : 'outline'}
          size="sm"
          onClick={onSetupQR}
          className="flex-1"
        >
          <QrCode className="w-4 h-4 mr-2" />
          {hasQR ? 'QR設定済み' : 'QRを登録'}
        </Button>
        
        <Button
          variant="ghost"
          size="icon"
          onClick={onDelete}
          className="text-destructive hover:text-destructive hover:bg-destructive/10"
        >
          <Trash2 className="w-4 h-4" />
        </Button>
      </div>

      {(!hasVoice || !hasQR) && (
        <p className="text-xs text-muted-foreground text-center">
          {!hasVoice && !hasQR && '声の録音とQRコードの登録が必要です'}
          {hasVoice && !hasQR && 'QRコードを登録してください'}
          {!hasVoice && hasQR && '声を録音してください'}
        </p>
      )}
    </motion.div>
  );
}
