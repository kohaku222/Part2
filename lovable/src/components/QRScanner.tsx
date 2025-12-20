import { useEffect, useRef, useState, useCallback } from 'react';
import { motion } from 'framer-motion';
import { ArrowLeft, Camera, Check, QrCode } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { BrowserMultiFormatReader } from '@zxing/library';

interface QRScannerProps {
  onScan: (code: string) => void;
  onBack: () => void;
  isSetup?: boolean;
  registeredCode?: string;
}

export function QRScanner({ onScan, onBack, isSetup = true, registeredCode }: QRScannerProps) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const readerRef = useRef<BrowserMultiFormatReader | null>(null);
  const [isScanning, setIsScanning] = useState(false);
  const [scannedCode, setScannedCode] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const startScanning = useCallback(async () => {
    if (!videoRef.current) return;

    try {
      const reader = new BrowserMultiFormatReader();
      readerRef.current = reader;
      setIsScanning(true);
      setError(null);

      await reader.decodeFromVideoDevice(
        undefined,
        videoRef.current,
        (result, err) => {
          if (result) {
            const code = result.getText();
            setScannedCode(code);
            
            if (!isSetup && registeredCode) {
              // Verify mode - check if codes match
              if (code === registeredCode) {
                onScan(code);
              } else {
                setError('登録されたコードと一致しません');
                setTimeout(() => setError(null), 2000);
              }
            }
          }
        }
      );
    } catch (err) {
      console.error('Camera error:', err);
      setError('カメラにアクセスできません');
      setIsScanning(false);
    }
  }, [isSetup, registeredCode, onScan]);

  const stopScanning = useCallback(() => {
    if (readerRef.current) {
      readerRef.current.reset();
      readerRef.current = null;
    }
    setIsScanning(false);
  }, []);

  const handleConfirm = () => {
    if (scannedCode) {
      onScan(scannedCode);
    }
  };

  useEffect(() => {
    startScanning();
    return () => stopScanning();
  }, [startScanning, stopScanning]);

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      className="min-h-screen flex flex-col bg-background"
    >
      <div className="flex items-center gap-4 p-6">
        <Button variant="ghost" size="icon" onClick={onBack}>
          <ArrowLeft className="w-5 h-5" />
        </Button>
        <h1 className="text-xl font-semibold">
          {isSetup ? 'QRコード登録' : 'スキャンしてアラーム停止'}
        </h1>
      </div>

      <div className="flex-1 flex flex-col items-center justify-center p-6 gap-6">
        <div className="relative w-full max-w-sm aspect-square rounded-2xl overflow-hidden bg-muted">
          <video
            ref={videoRef}
            className="w-full h-full object-cover"
            playsInline
          />
          
          {/* Scanner overlay */}
          <div className="absolute inset-0 flex items-center justify-center">
            <div className="w-48 h-48 border-2 border-primary rounded-2xl relative">
              <div className="absolute inset-0 scanner-line h-1 bg-primary/50" />
              
              {/* Corner markers */}
              <div className="absolute top-0 left-0 w-4 h-4 border-t-4 border-l-4 border-primary rounded-tl-lg" />
              <div className="absolute top-0 right-0 w-4 h-4 border-t-4 border-r-4 border-primary rounded-tr-lg" />
              <div className="absolute bottom-0 left-0 w-4 h-4 border-b-4 border-l-4 border-primary rounded-bl-lg" />
              <div className="absolute bottom-0 right-0 w-4 h-4 border-b-4 border-r-4 border-primary rounded-br-lg" />
            </div>
          </div>

          {!isScanning && (
            <div className="absolute inset-0 bg-background/80 flex items-center justify-center">
              <Camera className="w-12 h-12 text-muted-foreground" />
            </div>
          )}
        </div>

        {error && (
          <motion.p
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-destructive text-sm"
          >
            {error}
          </motion.p>
        )}

        {scannedCode && isSetup && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="glass-card p-4 w-full max-w-sm space-y-4"
          >
            <div className="flex items-center gap-3">
              <QrCode className="w-5 h-5 text-primary" />
              <div className="flex-1 min-w-0">
                <p className="text-sm text-muted-foreground">検出されたコード</p>
                <p className="font-mono text-sm truncate">{scannedCode}</p>
              </div>
            </div>
            
            <Button
              variant="glow"
              className="w-full"
              onClick={handleConfirm}
            >
              <Check className="w-4 h-4 mr-2" />
              このコードを登録
            </Button>
          </motion.div>
        )}

        <p className="text-sm text-muted-foreground text-center max-w-xs">
          {isSetup
            ? 'アラームを止めるためのQRコードまたはバーコードをスキャンして登録してください'
            : '登録したコードをスキャンしてアラームを止めてください'}
        </p>
      </div>
    </motion.div>
  );
}
