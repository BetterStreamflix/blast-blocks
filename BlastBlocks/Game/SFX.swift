import AVFoundation
import Foundation

enum SFX {
    private static var engine: AVAudioEngine?
    private static var player: AVAudioPlayerNode?
    private static var enabled = false

    static func warmup() {
        _ = ensureEngine()
    }

    private static func ensureEngine() -> AVAudioPlayerNode? {
        if let p = player { return p }
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)
        let e = AVAudioEngine()
        let p = AVAudioPlayerNode()
        e.attach(p)
        e.connect(p, to: e.mainMixerNode, format: nil)
        do {
            try e.start()
        } catch {
            return nil
        }
        engine = e
        player = p
        enabled = true
        return p
    }

    private static func tone(_ freq: Float, dur: Double = 0.09, vol: Float = 0.3, slide: Float = 0) {
        guard enabled || ensureEngine() != nil, let p = player, let engine = engine else { return }
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        let rate = format.sampleRate
        let frames = AVAudioFrameCount(rate * dur)
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return }
        buf.frameLength = frames
        for c in 0..<Int(format.channelCount) {
            guard let ch = buf.floatChannelData?[c] else { continue }
            for i in 0..<Int(frames) {
                let t = Float(i) / Float(rate)
                let env = Float(exp(-Double(t) * 16.0))
                let f = freq * (1 + slide * t)
                ch[i] = sinf(2 * .pi * f * t) * env * vol
            }
        }
        p.scheduleBuffer(buf)
        if !p.isPlaying { p.play() }
    }

    static func swap() { tone(300, dur: 0.05, vol: 0.16) }
    static func pop(depth: Int = 0) { tone(470 + Float(min(depth, 8)) * 80, dur: 0.09, vol: 0.3) }
    static func blast() { tone(170, dur: 0.24, vol: 0.45, slide: -0.55) }
    static func select() { tone(620, dur: 0.04, vol: 0.14) }
    static func fail() { tone(140, dur: 0.3, vol: 0.3, slide: -0.5) }

    static func win() {
        let notes: [Float] = [523, 659, 784, 1047]
        for (i, f) in notes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.1) {
                tone(f, dur: 0.16, vol: 0.32)
            }
        }
    }

    static func lose() {
        let notes: [Float] = [330, 262, 196]
        for (i, f) in notes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.12) {
                tone(f, dur: 0.18, vol: 0.28, slide: -0.15)
            }
        }
    }
}
