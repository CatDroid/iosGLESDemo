attribute vec4 vPosition;
attribute vec2 vTextureCoord;
varying vec2 vTextureCoordOut;

void main(void)
{
	vTextureCoordOut = vTextureCoord;
	gl_Position 	 = vPosition;
	
}
