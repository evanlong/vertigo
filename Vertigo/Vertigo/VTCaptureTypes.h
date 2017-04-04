//
//  VTCaptureTypes.h
//  Vertigo
//
//  Created by Evan Long on 3/26/17.
//
//

typedef NS_ENUM(NSInteger, VTRecordDirection) {
    VTRecordDirectionPull, // Start close and end far from object. Close -> Far
    VTRecordDirectionPush, // Start far and end close to object. Far -> Close
};

