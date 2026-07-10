import SwiftUI
import Playgrounds
import AVFoundation
import Combine
import CoreMotion



@main struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}


struct ContentView: View {
    @StateObject var audio: AudioController = AudioController()
    
    var body: some View {
        Text("Hello, world!")
            .padding()
            .onAppear {
                audio.player.position = AVAudio3DPoint(x: 0, y: 0, z: -3)
                audio.sideLeftPlayer.position = AVAudio3DPoint(x: -3, y: 0, z: -1)
                audio.sideRightPlayer.position = AVAudio3DPoint(x: 3, y: 0, z: -1)
                audio.rearOnePlayer.position = AVAudio3DPoint(x: 3, y: 0, z: 1.5)
                audio.rearTwoPlayer.position = AVAudio3DPoint(x: -3, y: 0, z: 1.5)
                audio.heightPlayer.position = AVAudio3DPoint(x: 0, y: 3, z: -1.5)
                
                // audio.startTracking()
                try? audio.engine.start()
                try? audio.player.playAudio()
                try? audio.sideLeftPlayer.playAudio()
                try? audio.sideRightPlayer.playAudio()
                try? audio.rearOnePlayer.playAudio()
                try? audio.rearTwoPlayer.playAudio()
                try? audio.heightPlayer.playAudio()
                
                print(String(audio.getPID(id: "com.spotify.client")))
                audio.tccPermissionFire(pid: audio.getPID(id: "com.spotify.client"))
                
            }
    }
}

#Preview {
    ContentView()
}
