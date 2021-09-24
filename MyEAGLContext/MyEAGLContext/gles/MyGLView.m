//
//  MyGLView.m
//  MyEAGLContext
//
//  Created by hehanlong on 2021/9/22.
//

#import "MyGLView.h"

// 关闭opengl警告  Apple-Clang Warnings All languate ---- Deprecated Function--NO
@implementation MyGLView
{
	// View相关
	CAEAGLLayer* _eaglLayer;
	
	// 线程相关
	CADisplayLink * _displayLink;
	NSThread*       _renderThread;
	BOOL _continueRunLoop;
	
	// opengl资源相关
	GLuint _colorRenderBuffer;
	GLuint _depthRenderBuffer;
	GLuint _frameBuffer;
	CGSize _rboSize ;
	CGRect _drawRect;
	
	// 纹理池
	NSMutableArray<NSNumber*>* _texturePool;
	GLuint _textureOrder ;

}


+(Class) layerClass
{
	return [CAEAGLLayer class];
}

#pragma mark 构造函数
-(instancetype)init
{
	self = [super init];
	[self _setup];
	return self ;
}

-(instancetype)initWithFrame:(CGRect)frame
{
	//self = [super initWithFrame:CGRectMake(0, 0, 200, 300)]; // 这里控制初始化生成Layer的bound/frame
	self = [super initWithFrame:frame];
	if (self)
	{
		[self _setup];
	}
	else
	{
		NSLog(@"fail to MyGLView super init");
	}
	return self;
}

-(instancetype)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder]; // 如果不调用这个 storyboard的内容不会显示 
	[self _setup];
	return self;
}

-(void) _setup
{
	_texturePool = [NSMutableArray new];
}

-(void) _setupLayer
{
	_eaglLayer = (CAEAGLLayer*) self.layer;

	// CALayer 默认是透明的，必须将它设为”不透明“ 才能让其可见
	_eaglLayer.opaque = YES ;
	//_eaglLayer.backgroundColor = CGColorCreateGenericRGB(1.0, 1.0, 0.0, 1.0); // 这个控制了什么都不处理时候layer的颜色

	// 只有两种 kEAGLColorFormatRGB565  kEAGLColorFormatRGBA8

	// 设置描绘属性，在这里设置”不维持渲染内容“以及颜色格式为 ”RGBA8“ ?? BGRA8 ??
	_eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
									 @(NO), kEAGLDrawablePropertyRetainedBacking,
									 kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
									 nil];

	// 默认是 1.0. 如果layer attach到view上 view会修改这个适合当前屏幕
	_eaglLayer.contentsScale = [UIScreen mainScreen].nativeScale;

	NSLog(@"layer size is layer'bound(%f,%f) frame(%f,%f)",
		  _eaglLayer.bounds.size.width, _eaglLayer.bounds.size.height,
		  _eaglLayer.frame.size.width, _eaglLayer.frame.size.height);
}

- (void) _setupContext
{
	EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES3; // gles 3.0
	//_context = [[EAGLContext alloc] initWithAPI:(EAGLRenderingAPI) sharegroup:(nonnull EAGLSharegroup *)] 共享上下文
	_context = [[EAGLContext alloc] initWithAPI:api];
	if (!_context)
	{
		NSLog(@"fail to create GLES 3.0 context");
		return ;
	}
	
	if (![EAGLContext setCurrentContext:_context]) // EGL::makeCurrent
	{
		_context = nil;
		NSLog(@"set current context to GLES 3.0 fail");
		return ;
	}
	NSLog(@"EAGLContext create and set ok");
	
	// [CATransaction flush]; ????
	

}


#pragma mark UIView的生命周期


// 可以认为是resize的回调?? 默认 子view自动resize和基于约束的行为 不符合要求
//-(void)layoutSubviews
//{
//
//}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


-(void) didMoveToWindow
{
	[super didMoveToWindow];
	NSLog(@"[MyGLView][didMoveToWindow] begin ------");
	
	
	if (_context == NULL) // GLK的context是外部提供的,我们这里如果没有提供的话 内部自己生成
	{
		[self _setupContext];
	}
	[self _setupLayer];

	[self _notifyResizeDrawable];


	// MyGLView内部通过CALink驱动渲染
	UIWindow* window = self.window;
	UIScreen* screen = window.screen;
	_displayLink = [screen displayLinkWithTarget:self selector:@selector(_notifyDrawFrame)];
	_displayLink.paused = false ;
	_displayLink.preferredFramesPerSecond = 60;


	_continueRunLoop = YES;
	_renderThread = [[NSThread alloc]initWithTarget:self selector:@selector(renderThreadLoop) object:nil];
	[_renderThread start];
	// TODO stop thread
	
	
	
	NSLog(@"[MyGLView][didMoveToWindow] end   ------");
	
}

#pragma mark - 渲染线程 -
-(void) renderThreadLoop
{

	NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
	
	BOOL continueRunLoop = YES;
	@synchronized (self) {
		continueRunLoop = self->_continueRunLoop;
	}
	
	[_displayLink addToRunLoop:runLoop forMode:@"CADisplayLinkMode"];
	
	while(continueRunLoop)
	{
		// 在NSThread RunLoop之前创建 autoreleasepool
		@autoreleasepool {
			[runLoop runMode:@"CADisplayLinkMode" beforeDate:[NSDate distantFuture]];
		}
		
		
		@synchronized (self) {
			continueRunLoop = self->_continueRunLoop;
		}
		
	}
}

#pragma mark - MyGLView的回调 onResize/onDraw -
-(void) _notifyResizeDrawable
{
	if (_eaglLayer == NULL)
	{
		NSLog(@"[_notifyResizeDrawable] _eaglLayer not ready ");
		return ;
	}
	
	CGFloat scale = [UIScreen mainScreen].scale;
	UIWindow* window = self.window;
	UIScreen* screen = window.screen;
	CGFloat nativeScale = screen.nativeScale;
	
	if (window == nil)
	{
		nativeScale = scale ;
	}
	else
	{
		NSLog(@"[_notifyResizeDrawable] UIWindow is not nil");
	}
	
	NSLog(@"[_notifyResizeDrawable] mainScreen'scale %f, UIWindow'screen'scale %f",
		  scale,
		  nativeScale);
	
	
	CGSize drawableSize = self.bounds.size; // 这个单位是point  UIView的尺寸
	drawableSize.width  = drawableSize.width  * nativeScale; // 乘以scale之后才是 像素
	drawableSize.height = drawableSize.height * nativeScale;
	if (drawableSize.width <= 0 || drawableSize.height <= 0)
	{
		NSLog(@"[_notifyResizeDrawable] newSize negative ");
		return;
	}
	
	
	@synchronized (_eaglLayer)
	{
		if (_rboSize.width == drawableSize.width && _rboSize.height == drawableSize.height)
		{
			return ;
		}
		
		NSLog(@"layersize from %f,%f to %f,%f ", _rboSize.width , _rboSize.height, drawableSize.width, drawableSize.height);
		// iphoneXR 828x1792
		
		if (![EAGLContext setCurrentContext:_context]) // EGL::makeCurrent
		{
			NSLog(@"set current context to GLES 3.0 fail");
			return ;
		}
		
	 
		[self _destoryRenderFrameBuffer];
		[self _setupRenderFrameBuffer:drawableSize];
		
		//	makeCurrent();
		//	GL_CHECK(glClearColor(0.0f, 0.0f, 0.0f, 0.0f) );
		//	GL_CHECK(glClear(GL_COLOR_BUFFER_BIT) );
		//	swap(NULL);
		//	GL_CHECK(glClear(GL_COLOR_BUFFER_BIT) );
		//	swap(NULL);
		
		// [self.delegate 回调通知延迟到  glkView:drawInRect:
	}
	
}


-(void) _notifyDrawFrame
{
	@synchronized (_eaglLayer)
	{
		if (![EAGLContext setCurrentContext:_context]) // EGL::makeCurrent
		{
			_context = nil;
			NSLog(@"set current context to GLES 3.0 fail");
			return ;
		}

		glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
		glViewport(0, 0, (GLsizei)_rboSize.width, (GLsizei)_rboSize.height);
		glClearColor(0.0, 1.0, 1.0, 1.0);
		glClear(GL_COLOR_BUFFER_BIT);


		if ([_texturePool count] != 0)
		{
			_textureOrder = ++_textureOrder % [_texturePool count];
			NSNumber* texId = [_texturePool objectAtIndex:_textureOrder];
			GLuint _id = [texId unsignedIntValue];
			[self->_delegate setTextureForTest:_id]; // 注释这里 就不会用纹理池中的纹理 
		}
		
		[self->_delegate glkView:self drawInRect:_drawRect];// rect包含了fbo尺寸的变化

		glBindFramebuffer(GL_FRAMEBUFFER, 0);

		glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer); // 必选先bind rbo才能把这个rbo显示出来
		[_context presentRenderbuffer:GL_RENDERBUFFER];
		glBindRenderbuffer(GL_RENDERBUFFER, 0);
	}
}

#pragma mark 内部函数

// 在sync(layer)的锁保护下
- (void) _setupRenderFrameBuffer:(CGSize)size ;
{
	// 返回RenderBuffer的ID 0是保留的 如果glBindRenderBuffer 0 就会取消之前的rbo的绑定
	//
	glGenRenderbuffers(1, &_colorRenderBuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
	
	// EAGLContext
	// Binds a drawable object’s storage to an OpenGL ES renderbuffer object.
	// 绑定一个‘可绘制对象’的内存到rbo
	// 创建可以呈现给屏幕的rbo,可以先绑定rbo,然后调用该方法,是rbo共享存储,这个rbo后面可使用presentRenderbuffer:呈现到屏幕
	// 宽和高 和 内部颜色格式 继承自 ‘可绘制对象’
	// 在调用这个函数之前, 可通过调用 ‘可绘制对象’的字典属性drawableProperties中kEAGLDrawablePropertyColorFormat来指定格式
	
	// 如果rbo要从drawable中分离 调用这个方法并且参数为nil
	
	// 为 color renderbuffer 分配存储空间 等价于 glRenderbufferStorage, 只有color部分可以，其他的比如 depth部分需要调用 glRenderbufferStorage
	// glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, width, height);
	[_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer]; // _eaglLayer是drawable, 可绘制对象, EAGLDrawable
	
	// 继承关系: CALayer<EAGLDrawable> <--- CAEAGLLayer
	 
	// 深度附件
	// glGenRenderbuffers(1, &_depthRenderBuffer);
	// glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
	// glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, size.width, size.height); // 内部格式是internalformat =  GL_DEPTH24_STENCIL8
	
	
	glGenFramebuffers(1, &_frameBuffer);
	glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
	
	// glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
	// glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
	
	
	glBindFramebuffer(GL_FRAMEBUFFER, 0);
	glBindRenderbuffer(GL_RENDERBUFFER, 0);
	
	_rboSize = size;
	_drawRect = CGRectMake(0, 0, size.width, size.height);
	
}


- (void) _destoryRenderFrameBuffer
{
	

	if (_frameBuffer != 0)
	{
		glDeleteFramebuffers(1, &_frameBuffer);
		_frameBuffer = 0;
	}
	
	if (_colorRenderBuffer !=  0)
	{
		glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
		[_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:nil];
		glBindRenderbuffer(GL_RENDERBUFFER, 0);
		
		glDeleteRenderbuffers(1, &_colorRenderBuffer);
		_colorRenderBuffer = 0;
	}
	
	if (_depthRenderBuffer != 0)
	{
		glDeleteRenderbuffers(1, &_depthRenderBuffer);
		_depthRenderBuffer = 0;
	}
	
}


-(void) generateTexture
{
	@synchronized (_eaglLayer)
	{
		if (![EAGLContext setCurrentContext:_context]) // EGL::makeCurrent
		{
			_context = nil;
			NSLog(@"set current context to GLES 3.0 fail");
			return ;
		}
		
		GLuint texId;
		glGenTextures(1, &texId);
		glBindTexture(GL_TEXTURE_2D, texId);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		
		glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
		
		int* pixelBytes = (int*)malloc(_rboSize.width * 4 * _rboSize.height);
		
		for (int i = 0 ; i < _rboSize.width * _rboSize.height; i++)
		{
			pixelBytes[i] = 0xFF00FF77; // A B G R
		}
		// GL_RGBA 的意思是 从 低地址到高地址是 R G  B A 的顺序
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _rboSize.width, _rboSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixelBytes);
		//glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _rboSize.width, _rboSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
		
		free(pixelBytes);
		
		glBindTexture(GL_TEXTURE_2D, 0);
		
		GLenum error = glGetError();
		if (error != GL_NO_ERROR)
		{
			NSLog(@"Fatal error !!");
		}
		
		[_texturePool addObject:[NSNumber numberWithUnsignedInt:texId]];
		
		NSLog(@"add texId %u (%lu %lu) in pool size: %lu",
			  texId,
			  (unsigned long)_rboSize.width,
			  (unsigned long)_rboSize.height,
			  (unsigned long)[_texturePool count] );
		
		
	}
}


-(void) deleteTexture
{
	@synchronized (_eaglLayer)
	{
		if (![EAGLContext setCurrentContext:_context]) // EGL::makeCurrent
		{
			_context = nil;
			NSLog(@"set current context to GLES 3.0 fail");
			return ;
		}
	
		GLuint uTexId = 0 ; // 0 是保留的id 不会分配出来
		if (_texturePool.count > 0)
		{
			NSNumber* texId = [_texturePool firstObject];
			[_texturePool removeObjectAtIndex:0];
			uTexId = [texId unsignedIntValue];
			glDeleteTextures(1, &uTexId);
		}
		NSLog(@"rm tex: %u in pool size: %lu", uTexId, (unsigned long)[_texturePool count]);
		
	}
}


@end



