precision mediump float;

varying vec2 vTextureCoordOut;

uniform sampler2D Sampler;

void main()
{
	gl_FragColor = texture2D(Sampler, vTextureCoordOut);
}
