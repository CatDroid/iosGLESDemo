//
//  ViewDelegateRender.h
//  MyEAGLContext
//
//  Created by hehanlong on 2021/9/24.
//

#import <Foundation/Foundation.h>

#import "MyGLView.h"

NS_ASSUME_NONNULL_BEGIN


@interface ViewDelegateRender : NSObject<GLViewDelegate>


-(void) glkView:(MyGLView*)view drawInRect:(CGRect) rect ;

-(void) setTextureForTest:(GLuint) _tex ;

@end

NS_ASSUME_NONNULL_END
