//
//  MyGLView.h
//  MyEAGLContext
//
//  Created by hehanlong on 2021/9/22.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES3/gl.h>

NS_ASSUME_NONNULL_BEGIN

@protocol GLViewDelegate ;

@interface MyGLView : UIView


@property (strong,atomic) EAGLContext* context ;
@property (weak,atomic,nullable) id<GLViewDelegate> delegate ;


-(instancetype)init; // ViewContorller 不调用UIView的 init 或者 initWithFrame 而是 initWithCoder!
-(instancetype)initWithFrame:(CGRect)frame;
-(instancetype)initWithCoder:(NSCoder *)coder;


// 测试metal、openg分配纹理内存占用
-(void) generateTexture;
-(void) deleteTexture;


@end

@protocol GLViewDelegate <NSObject>

// Metal's Delegate
//-(void) OnDrawableSizeChange:(CGSize)size WithView:(MyGLView*) view;
//-(void) OnDrawFrame:(CAMetalLayer*) layer WithView:(MyGLView*) view;

-(void) setTextureForTest:(GLuint) _tex ;

// GLKit's Delegate
-(void) glkView:(MyGLView*)view drawInRect:(CGRect) rect ;

@end



NS_ASSUME_NONNULL_END
