import Foundation
import WebRTC
import GRPCCore
import NIO
import SwiftProtobuf
import NIOTransportServices

typealias SignalingClient = Signaling_SignalingService.Client<NIOTransportServices>

class WebRTCClient: NSObject, ObservableObject, RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
    }

    
    // MARK: - Published Properties
    
    @Published var localVideoView: UIView? // 로컬 카메라/화면 뷰
    @Published var remoteVideoView: UIView? // 상대방 비디오 뷰
    @Published var isConnected: Bool = false
    
    private var client: SignalingClient?
    private let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
    private var peerConnection: RTCPeerConnection?
    private let peerConnectionFactory = RTCPeerConnectionFactory()

    
    override init() {
        super.init()
        setupGRPCClient()
    }
    
    deinit {
        try? group.syncShutdownGracefully()
        self.peerConnection?.close()
    }
    
    
    private func setupGRPCClient() {
        let transport = NIOClientTransport(
            host: "127.0.0.1",
            port: 1234,
            eventLoopGroup: self.group,
        )
            
        self.client = SignalingClient(wrapping: GRPCCore.GRPCClient(transport: transport))
    }
    

    func sendOffer(sdp: String, clientId: String) async throws {
        let offerMsg = Signaling_SdpMessage.with {
            $0.type = "offer"
            $0.sdp = sdp
        }
        
        let clientInfo = try Signaling_ClientInfo.with {
            $0.clientID = clientId
            $0.sdp = try offerMsg.jsonString() // 메시지를 JSON으로 변환
        }
        
        let response = try await client?.sendMessage(clientInfo)
        print("Offer sent. Response from: \(response?.clientID ?? "N/A")")
    }

    func sendAnswer(sdp: String, clientId: String) async throws {
        let answerMsg = Signaling_SdpMessage.with {
            $0.type = "answer"
            $0.sdp = sdp
        }
        
        let clientInfo = try Signaling_ClientInfo.with {
            $0.clientID = clientId
            $0.sdp = try answerMsg.jsonString()
        }
        
        _ = try await client?.sendMessage(clientInfo)
    }

    func sendCandidate(candidate: RTCIceCandidate, clientId: String) async throws {
        let candidateMsg = Signaling_CandidateMessage.with {
            $0.sdpMid = candidate.sdpMid ?? ""
            $0.sdpMlineIndex = Int32(candidate.sdpMLineIndex)
            $0.sdp = candidate.sdp
        }
        
        let clientInfo = try Signaling_ClientInfo.with {
            $0.clientID = clientId
            $0.candidate = try candidateMsg.jsonString()
        }
        
        _ = try await client?.sendMessage(clientInfo)
    }
    
    func receiveMessages(clientId: String) async throws {
        let clientInfo = Signaling_ClientInfo.with { $0.clientID = clientId }
        let request = GRPCCore.ClientRequest.init(message: clientInfo)

        guard let call = client?.joinRoom(request: request) else {
            print("Error: gRPC call to joinRoom failed to initialize.")
            return
        }
            
        for try await message in call.responseStream {
               guard let pc = peerConnection else { continue }
               
               // async
               if !message.sdp.isEmpty {
                   let sdpMessage = try Signaling_SdpMessage(jsonString: message.sdp)
                   let sdp = RTCSessionDescription(type: sdpMessage.type == "offer" ? .offer : .answer, sdp: sdpMessage.sdp)
                   
                   try await pc.setRemoteDescription(sdp)
                   
                   if sdp.type == .offer {
                       await self.generateAndSendAnswer(clientId: clientId)
                   }
               }
            
               else if !message.candidate.isEmpty {
                   let candidateMsg = try Signaling_CandidateMessage(jsonString: message.candidate)
                   let candidate = RTCIceCandidate(
                       sdp: candidateMsg.sdp,
                       sdpMLineIndex: Int32(candidateMsg.sdpMlineIndex), sdpMid: candidateMsg.sdpMid
                   )
                   await pc.add(candidate)
               }
           }
    }

    
    // WebRTC Delegate
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("Signaling state changed: \(stateChanged.rawValue)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("Received remote stream.")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        print("Generated ICE Candidate: \(candidate.sdp)")
        //Task { try await sendCandidate(...) } )
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        switch newState {
        case .connected:
            DispatchQueue.main.async { self.isConnected = true }
            print("ICE Connection State: Connected!")
        case .disconnected, .closed, .failed:
            DispatchQueue.main.async { self.isConnected = false }
            print("ICE Connection State: \(newState.rawValue)")
        default:
            break
        }
    }

    // 다른 델리게이트 메서드들은 필요에 따라 추가됩니다.
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {}
}
