import QRCode from 'qrcode.react'
import { useRef } from 'react'
import './QRCodeGenerator.css'

export default function QRCodeGenerator({ data, label = 'Scan QR Code', size = 256, downloadName = 'qrcode' }) {
  const qrRef = useRef()

  const downloadQR = () => {
    const canvas = qrRef.current.querySelector('canvas')
    const url = canvas.toDataURL('image/png')
    const link = document.createElement('a')
    link.href = url
    link.download = `${downloadName}.png`
    link.click()
  }

  return (
    <div className="qr-generator-container">
      <div className="qr-code-wrapper" ref={qrRef}>
        <QRCode 
          value={data || 'No data'} 
          size={size}
          level="H"
          includeMargin={true}
          renderAs="canvas"
        />
      </div>
      <p className="qr-label">{label}</p>
      <button onClick={downloadQR} className="btn-download">
        Download QR Code
      </button>
    </div>
  )
}
