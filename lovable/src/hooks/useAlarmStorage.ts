import { useState, useEffect, useCallback } from 'react';
import { Alarm } from '@/types/alarm';

const STORAGE_KEY = 'motivation-alarm-data';

export function useAlarmStorage() {
  const [alarm, setAlarm] = useState<Alarm | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored) {
      try {
        const parsed = JSON.parse(stored);
        setAlarm(parsed);
      } catch (error) {
        console.error('Error parsing stored alarm:', error);
      }
    }
    setIsLoading(false);
  }, []);

  const saveAlarm = useCallback((newAlarm: Alarm) => {
    setAlarm(newAlarm);
    // Save without blob (can't stringify blob)
    const toStore = { ...newAlarm, voiceRecording: undefined };
    localStorage.setItem(STORAGE_KEY, JSON.stringify(toStore));
  }, []);

  const updateAlarm = useCallback((updates: Partial<Alarm>) => {
    setAlarm(prev => {
      if (!prev) return null;
      const updated = { ...prev, ...updates };
      const toStore = { ...updated, voiceRecording: undefined };
      localStorage.setItem(STORAGE_KEY, JSON.stringify(toStore));
      return updated;
    });
  }, []);

  const deleteAlarm = useCallback(() => {
    setAlarm(null);
    localStorage.removeItem(STORAGE_KEY);
  }, []);

  return {
    alarm,
    isLoading,
    saveAlarm,
    updateAlarm,
    deleteAlarm,
    setAlarm,
  };
}
