import { useEffect, useRef, useState } from 'react'
import { Html5QrcodeScanner } from 'html5-qrcode'
import './QRCodeScanner.css'

export default function QRCodeScanner({ onScan, onError }) {
  const scannerRef = useRef(null)
  const [isScanning, setIsScanning] = useState(false)
  const scannerInstanceRef = useRef(null)

  useEffect(() => {
    if (!isScanning || !scannerRef.current) return

    const scanner = new Html5QrcodeScanner(
      'qr-reader',
      {
        fps: 10,
        qrbox: { width: 250, height: 250 },
        aspectRatio: 1.0,
      },
      false
    )

    scannerInstanceRef.current = scanner

    const onScanSuccess = (decodedText) => {
      onScan(decodedText)
      scanner.clear()
      setIsScanning(false)
    }

    const onScanError = (error) => {
      // Silently ignore scanning errors
      if (onError) onError(error)
    }

    scanner.render(onScanSuccess, onScanError)

    return () => {
      if (scannerInstanceRef.current) {
        scannerInstanceRef.current.clear().catch(() => {})
      }
    }
  }, [isScanning, onScan, onError])

  const toggleScanning = () => {
    setIsScanning(!isScanning)
  }

  return (
    <div className="qr-scanner-container">
      <button 
        onClick={toggleScanning}
        className={`btn-toggle-scan ${isScanning ? 'active' : ''}`}
      >
        {isScanning ? 'Stop Scanning' : 'Start QR Scanner'}
      </button>
      
      {isScanning && (
        <div className="scanner-wrapper">
          <div id="qr-reader" style={{ width: '100%', marginTop: '1rem' }}></div>
          <p className="scan-hint">Point your camera at a QR code</p>
        </div>
      )}
    </div>
  )
}
