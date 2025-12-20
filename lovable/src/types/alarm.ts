export interface Alarm {
  id: string;
  time: string; // HH:MM format
  enabled: boolean;
  voiceRecording?: Blob;
  voiceRecordingUrl?: string;
  qrCode?: string;
  label?: string;
}

export type AppView = 'main' | 'set-alarm' | 'record-voice' | 'scan-setup' | 'alarm-ringing' | 'motivation-playback';
