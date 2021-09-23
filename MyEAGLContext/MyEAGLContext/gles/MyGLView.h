//
//  MyGLView.h
//  MyEAGLContext
//
//  Created by hehanlong on 2021/9/22.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES3/gl.h>

NS_ASSUME_NONNULL_BEGIN

@protocol GLViewDelegate <NSObject>

@end

@interface MyGLView : UIView

//-(instancetype)init NS_UNAVAILABLE;

-(instancetype)init; // ViewContorller 不调用UIView的 init 或者 initWithFrame 而是 initWithCoder!
-(instancetype)initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;
-(instancetype)initWithCoder:(NSCoder *)coder;


@property (strong,atomic) EAGLContext* context ;
@property (weak,atomic,nullable) id<GLViewDelegate> delegate ;

@end

@protocol GLViewDelegate <NSObject>

// Metal's Delegate
//-(void) OnDrawableSizeChange:(CGSize)size WithView:(MyGLView*) view;
//-(void) OnDrawFrame:(CAMetalLayer*) layer WithView:(MyGLView*) view;

// GLKit's Delegate
-(void) glkView:(MyGLView*)view drawInRect:(CGRect) rect ;

@end



NS_ASSUME_NONNULL_END
