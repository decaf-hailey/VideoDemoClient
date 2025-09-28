//
//  ContentView.swift
//  VideoDemoClient
//
//  Created by hailey on 9/28/25.
//

import SwiftUI
import WebRTC
import GRPCCore
import NIO
import SwiftProtobuf

struct UIViewWrapper: UIViewRepresentable {
    let uiView: UIView?

    func makeUIView(context: Context) -> UIView {
        return uiView ?? UIView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {
    }
}


struct ContentView: View {
    @StateObject private var client = WebRTCClient()
    
    private let clientId = UUID().uuidString

    var body: some View {
        VStack {
            
            Text("Local Video")
                .font(.headline)
            UIViewWrapper(uiView: client.localVideoView)
                .frame(height: 200)
                .background(Color.black.opacity(0.1))
                .cornerRadius(10)
            
            Text("Remote Video")
                .font(.headline)
                .padding(.top)
            UIViewWrapper(uiView: client.remoteVideoView)
                .frame(height: 200)
                .background(Color.black.opacity(0.1))
                .cornerRadius(10)
            
            HStack {
                Button("Join Room") {
                    Task {
                        try await client.receiveMessages(clientId: clientId)
                    }
                }
                .padding()
                
                Button("Send Offer (Test)") {
                    Task {
                        let dummySdp = "v=0\no=- 0 0 IN IP4 0.0.0.0\r\ns=-\r\n..."
                        try await client.sendOffer(sdp: dummySdp, clientId: clientId)
                    }
                }
                .padding()
            }
        }
        .padding()
        .onAppear {
        }
    }
}

#Preview {
    ContentView()
}
