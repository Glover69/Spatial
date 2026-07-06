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
                
                audio.startTracking()
                try? audio.engine.start()
                try? audio.player.playAudio()
                print(String(audio.getPID(id: "com.spotify.client")))
                audio.tccPermissionFire(pid: audio.getPID(id: "com.spotify.client"))
                
            }
    }
}

#Preview {
    ContentView()
}
