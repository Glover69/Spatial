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
                try? audio.engine.start()
                // audio.playTone()
                print(String(audio.getPID(id: "com.spotify.client")))
                audio.tccPermissionFire(pid: audio.getPID(id: "com.spotify.client"))
                
            }
    }
}

#Preview {
    ContentView()
}
