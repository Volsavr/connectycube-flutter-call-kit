//
//  VoIPController.swift
//  connectycube_flutter_call_kit
//
//  Created by Tereha on 19.11.2021.
//  Modified by Volsavr 26.02.2024
//

import Foundation
import PushKit

class VoIPController : NSObject{
    let callKitController: CallKitController
    var tokenListener : ((String)->Void)?
    var voipToken: String?

        private static let paramType = "type"
        private static let paramData = "data"
        private static let paramTimestamp = "timestamp"
        private static let paramCallId = "call_id"
        private static let paramSipLineId = "device_sip_account_id"
        private static let paramFromDisplayName = "from_display_name"
        private static let paramFromUser = "from_user"
        private static let paramReason = "reason"
        private static let paramBornAt = "born_at"

        private static let signalTypeCallStart = "cc_call_start"
        private static let callNotificationTimeout = 10
    
    public required init(withCallKitController callKitController: CallKitController) {
        self.callKitController = callKitController
        super.init()
        
        //http://stackoverflow.com/questions/27245808/implement-pushkit-and-test-in-development-behavior/28562124#28562124
        let pushRegistry = PKPushRegistry(queue: .main)
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = Set<PKPushType>([.voIP])
    }
    
    func getVoIPToken() -> String? {
        print("[VoIPController][getVoIPToken] \(voipToken)")
        return voipToken
    }
}

//MARK: VoIP Token notifications
extension VoIPController: PKPushRegistryDelegate {

    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        if pushCredentials.token.count == 0 {
            print("[VoIPController][pushRegistry] No device token!")
            return
        }
        
        print("[VoIPController][pushRegistry] token: \(pushCredentials.token)")
        
        let deviceToken: String = pushCredentials.token.reduce("", {$0 + String(format: "%02X", $1) })
        print("[VoIPController][pushRegistry] deviceToken: \(deviceToken)")
        
        self.voipToken = deviceToken
        
        if tokenListener != nil {
            print("[VoIPController][pushRegistry] notify listener")
            tokenListener!(self.voipToken!)
        }
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        print("[VoIPController][pushRegistry][didReceiveIncomingPushWith] payload: \(payload.dictionaryPayload)")
        
        let callData = payload.dictionaryPayload

        if type == .voIP{

            let signalingType = callData[VoIPController.paramType] as? String;

            if(signalingType != VoIPController.signalTypeCallStart) {
                print("[VoIPController][didReceiveIncomingPushWith] unknown 'signal_type' was received")
                completion()
                return;
            }

            let data = callData[VoIPController.paramData] as! [String: Any]

            let bornAt = Double(data[VoIPController.paramBornAt] as! String)
            
            let now = Int64(Date().timeIntervalSince1970)

             if(now - Int64(bornAt!) > VoIPController.callNotificationTimeout) {
                print("[VoIPController][didReceiveIncomingPushWith] Message too old for processing a notification")
                completion()
                return;
             }

             let callId = data[VoIPController.paramCallId] as! String

             let callUuid = Utils.uuid(string: callId)

             var displayName = data[VoIPController.paramFromDisplayName] as? String
             
            if(displayName == nil ||  displayName!.isEmpty){
                displayName = data[VoIPController.paramFromUser] as! String
            }
            
             let opponents: [Int] = [1]

             self.callKitController.reportIncomingCall(uuid: callUuid.uuidString.lowercased(),
                  callType: 0, callInitiatorId: 0,
                  callInitiatorName: displayName!,
                  opponents: opponents,
                  userInfo : nil) { (error) in

                            completion()

                            if(error == nil){
                                print("[VoIPController][didReceiveIncomingPushWith] reportIncomingCall SUCCESS")
                            } else {
                                print("[VoIPController][didReceiveIncomingPushWith] reportIncomingCall ERROR: \(error?.localizedDescription ?? "none")")
                            }
                  }

        } else {
          completion()
        }

        /*if type == .voIP{
            let callId = callData["session_id"] as! String
            let signalingType = callData["signal_type"] as? String
            
            if (signalingType != nil && (signalingType == "endCall" || signalingType == "rejectCall")) {
                self.callKitController.reportCallEnded(uuid: UUID(uuidString: callId.lowercased())!, reason: CallEndedReason.remoteEnded)
                
                completion()
            } else if (signalingType != nil && signalingType == "startCall") {
                let callType = callData["call_type"] as! Int
                let callInitiatorId = callData["caller_id"] as! Int
                let callInitiatorName = callData["caller_name"] as! String
                let callOpponentsString = callData["call_opponents"] as! String
                let callOpponents = callOpponentsString.components(separatedBy: ",")
                    .map { Int($0) ?? 0 }
                let userInfo = callData["user_info"] as? String
                
                self.callKitController.reportIncomingCall(uuid: callId.lowercased(), callType: callType, callInitiatorId: callInitiatorId, callInitiatorName: callInitiatorName, opponents: callOpponents, userInfo: userInfo) { (error) in
                    
                    completion()
                    
                    if(error == nil){
                        print("[VoIPController][didReceiveIncomingPushWith] reportIncomingCall SUCCESS")
                    } else {
                        print("[VoIPController][didReceiveIncomingPushWith] reportIncomingCall ERROR: \(error?.localizedDescription ?? "none")")
                    }
                }
            } else {
                print("[VoIPController][didReceiveIncomingPushWith] unknown 'signal_type' was received")
                completion()
            }
        } else {
            completion()
        }*/
    }

}
