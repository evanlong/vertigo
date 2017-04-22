//
//  VertigoDefines.h
//  Vertigo
//
//  Created by Evan Long on 4/22/17.
//
//

#ifdef __cplusplus
    #define VT_EXTERN extern "C" __attribute__((visibility ("default")))
#else
    #define VT_EXTERN extern __attribute__((visibility ("default")))
#endif
