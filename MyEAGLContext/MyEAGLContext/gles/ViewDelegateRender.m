//
//  ViewDelegateRender.m
//  MyEAGLContext
//
//  Created by hehanlong on 2021/9/24.
//

#import "ViewDelegateRender.h"
#import "GLESUtils.h"

@implementation ViewDelegateRender
{
	// flag
	CGSize currentRender ;
	bool isSetup ;
	
	// opengl相关
	GLuint _programHandle;
	
	// For Vertex
	//
	GLuint _positionSlot;
	GLuint _modelViewSlot;
	GLuint _projectionSlot;
	
	// For light
	//
	GLuint _normalMatrixSlot;
	GLuint _lightPositionSlot;
	GLint _normalSlot;
	GLint _ambientSlot;
	GLint _diffuseSlot;
	GLint _specularSlot;
	GLint _shininessSlot;
	
	// For texture
	//
	NSUInteger _textureCount;
	GLuint * _textures;
	GLint _textureCoordSlot;
	GLint _samplerSlot;
	
	// For VBO
	GLuint _vbo;
		
	// for test
	GLuint _testTexture;
}

-(void) setTextureForTest:(GLuint) _tex
{
	_testTexture = _tex ;
}


-(void) glkView:(MyGLView*)view drawInRect:(CGRect) rect
{
	if (!isSetup)
	{
		isSetup = true ;
		[self _setup];
		
	}
	
	if (currentRender.width != rect.size.width || currentRender.height != rect.size.height)
	{
		currentRender = rect.size ;
		[self _onResize:currentRender];
	}
	
	glUseProgram(_programHandle);
	
	glBindTexture(GL_TEXTURE_2D, _testTexture); // TODO 绑定纹理
	glActiveTexture(GL_TEXTURE0);
	glUniform1i(_samplerSlot, 0);
	
	glBindBuffer(GL_ARRAY_BUFFER, _vbo);
	
	glEnableVertexAttribArray(_positionSlot);
	glVertexAttribPointer(_positionSlot, 2, GL_FLOAT, GL_FALSE, sizeof(float) * 4 , (void*)0);
	
	glEnableVertexAttribArray(_textureCoordSlot);
	glVertexAttribPointer(_textureCoordSlot, 2, GL_FLOAT, GL_FALSE, sizeof(float) * 4 , (void*)(sizeof(float) * 2) );
	

	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	

	glDisableVertexAttribArray(_positionSlot);
	glDisableVertexAttribArray(_textureCoordSlot);
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	
}


-(void) _setup
{
	// load program
	NSString * vertexShaderPath = [[NSBundle mainBundle] pathForResource:@"vert" ofType:@"glsl"];
	NSString * fragmentShaderPath = [[NSBundle mainBundle] pathForResource:@"frag" ofType:@"glsl"];
	
	_programHandle = [GLESUtils loadProgram:vertexShaderPath withFragmentShaderFilepath:fragmentShaderPath];
	if (_programHandle == 0)
	{
		NSLog(@" >> Error: Failed to setup program.");
		return;
	}
	
	glUseProgram(_programHandle);
	
	[self _getSlotsFromProgram];
	
	const float data[] = {
		-1.0, -1.0, 0.0, 1.0,
		 1.0, -1.0, 1.0, 1.0,
		-1.0,  1.0, 0.0, 0.0,
		 1.0 , 1.0, 1.0, 0.0
	};
	glGenBuffers(1, &_vbo);
	glBindBuffer(GL_ARRAY_BUFFER, _vbo);
	glBufferData(GL_ARRAY_BUFFER, sizeof(data), data, GL_STATIC_DRAW);
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	
	// _positionSlot
	// _textureCoordSlot
	// Sampler
	
}

- (void) _getSlotsFromProgram
{
	// Get the attribute and uniform slot from program
	//
	_projectionSlot 	= glGetUniformLocation(_programHandle, "projection");
	_modelViewSlot 		= glGetUniformLocation(_programHandle, "modelView");
	_normalMatrixSlot 	= glGetUniformLocation(_programHandle, "normalMatrix");
	_lightPositionSlot 	= glGetUniformLocation(_programHandle, "vLightPosition");
	_ambientSlot 		= glGetUniformLocation(_programHandle, "vAmbientMaterial");
	_specularSlot 		= glGetUniformLocation(_programHandle, "vSpecularMaterial");
	_shininessSlot 		= glGetUniformLocation(_programHandle, "shininess");
	
	_positionSlot 		= glGetAttribLocation(_programHandle,  "vPosition");
	_normalSlot 		= glGetAttribLocation(_programHandle,  "vNormal");
	_diffuseSlot 		= glGetAttribLocation(_programHandle,  "vDiffuseMaterial");
	
	_textureCoordSlot 	= glGetAttribLocation(_programHandle,  "vTextureCoord");
	_samplerSlot 		= glGetUniformLocation(_programHandle, "Sampler");
}


-(void) _onResize:(CGSize) size
{
	CGFloat width  = size.width;
	CGFloat height = size.height;
	
	// re-Create size fbo/tex
	
}


@end
