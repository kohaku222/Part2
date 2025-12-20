import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';

interface TimeDisplayProps {
  showSeconds?: boolean;
  size?: 'sm' | 'md' | 'lg' | 'xl';
}

export function TimeDisplay({ showSeconds = false, size = 'lg' }: TimeDisplayProps) {
  const [time, setTime] = useState(new Date());

  useEffect(() => {
    const interval = setInterval(() => {
      setTime(new Date());
    }, 1000);

    return () => clearInterval(interval);
  }, []);

  const hours = time.getHours().toString().padStart(2, '0');
  const minutes = time.getMinutes().toString().padStart(2, '0');
  const seconds = time.getSeconds().toString().padStart(2, '0');

  const sizeClasses = {
    sm: 'text-3xl',
    md: 'text-5xl',
    lg: 'text-7xl',
    xl: 'text-9xl',
  };

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.9 }}
      animate={{ opacity: 1, scale: 1 }}
      className="flex items-center justify-center"
    >
      <span className={`time-display ${sizeClasses[size]}`}>
        {hours}:{minutes}
        {showSeconds && (
          <span className="text-muted-foreground opacity-50">:{seconds}</span>
        )}
      </span>
    </motion.div>
  );
}
