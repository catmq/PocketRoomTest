//
//  GLModel.h
//
//  GLView Project
//  Version 1.6.1
//
//  Created by Nick Lockwood on 10/07/2011.
//  Copyright 2011 Charcoal Design
//
//  Distributed under the permissive zlib License
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/GLView
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#import "GLModel.h"


#pragma GCC diagnostic ignored "-Wobjc-missing-property-synthesis"
#pragma GCC diagnostic ignored "-Wdirect-ivar-access"
#pragma GCC diagnostic ignored "-Wpointer-arith"
#pragma GCC diagnostic ignored "-Wconversion"
#pragma GCC diagnostic ignored "-Wgnu"


typedef struct
{
    char fileIdentifier[32];
    unsigned int majorVersion;
    unsigned int minorVersion;
}
WWDC2010Header;


typedef struct
{
    unsigned int attribHeaderSize;
    unsigned int byteElementOffset;
    unsigned int bytePositionOffset;
    unsigned int byteTexcoordOffset;
    unsigned int byteNormalOffset;
}
WWDC2010TOC;


typedef struct
{
    unsigned int byteSize;
    GLenum datatype;
    GLenum primType;
    unsigned int sizePerElement;
    unsigned int numElements;
}
WWDC2010Attributes;


@interface NSString (Private)

- (NSString *)GL_normalizedPathWithDefaultExtension:(NSString *)extension;

@end


@interface NSData (Private)

- (NSData *)GL_unzippedData;

@end


@interface GLModel ()

@property (nonatomic, assign) GLfloat *vertices;
@property (nonatomic, assign) GLfloat *texCoords;
@property (nonatomic, assign) GLfloat *normals;
@property (nonatomic, assign) void *elements;
@property (nonatomic, assign) GLuint componentCount;
@property (nonatomic, assign) GLuint vertexCount;
@property (nonatomic, assign) GLuint elementCount;
@property (nonatomic, assign) GLuint elementSize;
@property (nonatomic, assign) GLenum elementType;

//
@property (nonatomic, assign) GLfloat *centerpos;

@end


@implementation GLModel

- (void)dealloc
{
    free(_vertices);
    free(_texCoords);
    free(_normals);
    free(_elements);
}


#pragma mark -
#pragma mark Private

- (BOOL)loadAppleWWDC2010Model:(NSData *)data
{
    if ([data length] < sizeof(WWDC2010Header) + sizeof(WWDC2010TOC))
    {
        //can't be correct file type
        return NO;  
    }
    
    //check header
    WWDC2010Header *header = (WWDC2010Header *)[data bytes];
    if(strncmp(header->fileIdentifier, "AppleOpenGLDemoModelWWDC2010", sizeof(header->fileIdentifier)))
    {
        return NO;
    }
    if(header->majorVersion != 0 && header->minorVersion != 1)
    {
        return NO;
    }
    
    //load table of contents
    WWDC2010TOC *toc = (WWDC2010TOC *)((WWDC2010TOC *)[data bytes] + sizeof(WWDC2010Header));
    if(toc->attribHeaderSize > sizeof(WWDC2010Attributes))
    {
        return NO;
    }
    
    //copy elements
    WWDC2010Attributes *elementAttributes = (WWDC2010Attributes *)((WWDC2010Attributes *)[data bytes] + toc->byteElementOffset);
    if (elementAttributes->primType != GL_TRIANGLES)
    {
        //TODO: extend GLModel with support for other primitive types
        return NO;
    }
    self.elementSize = elementAttributes->byteSize / elementAttributes->numElements;
    switch (self.elementSize) {
        case sizeof(GLuint):
            self.elementType = GL_UNSIGNED_INT_OES;
            break;
        case sizeof(GLushort):
            self.elementType = GL_UNSIGNED_SHORT;
            break;
        case sizeof(GLubyte):
            self.elementType = GL_UNSIGNED_BYTE;
            break;
    }
    self.elementCount = elementAttributes->numElements;
    self.elements = malloc(elementAttributes->byteSize);
    memcpy(self.elements, elementAttributes + 1, elementAttributes->byteSize);
        
    //copy vertex data
    WWDC2010Attributes *vertexAttributes = (WWDC2010Attributes *)((WWDC2010Attributes *)[data bytes] + toc->bytePositionOffset);
    if (vertexAttributes->datatype != GL_FLOAT)
    {
        //TODO: extend GLModel with support for other data types
        return NO;
    }
    self.componentCount = 4;
    self.vertexCount = vertexAttributes->numElements;
    self.vertices = (GLfloat *)malloc(vertexAttributes->byteSize);
    memcpy(self.vertices, vertexAttributes + 1, vertexAttributes->byteSize);
    
    //copy text coord data
    WWDC2010Attributes *texCoordAttributes = (WWDC2010Attributes *)((WWDC2010Attributes *)[data bytes] + toc->byteTexcoordOffset);
    if (texCoordAttributes->datatype != GL_FLOAT)
    {
        //TODO: extend GLModel with support for other data types
        return NO;
    }
    if (texCoordAttributes->byteSize)
    {
        self.texCoords = (GLfloat *)malloc(texCoordAttributes->byteSize);
        memcpy(self.texCoords, texCoordAttributes + 1, texCoordAttributes->byteSize);
    }
    
    //copy normal data
    WWDC2010Attributes *normalAttributes = (WWDC2010Attributes *)((WWDC2010Attributes *)[data bytes] + toc->byteNormalOffset);
    if (normalAttributes->datatype != GL_FLOAT)
    {
        //TODO: extend GLModel with support for other data types
        return NO;
    }
    if (normalAttributes->byteSize)
    {
        self.normals = (GLfloat *)malloc(normalAttributes->byteSize);
        memcpy(self.normals, normalAttributes + 1, normalAttributes->byteSize);
    }
    
    //success
    return YES;
}

- (BOOL)loadObjModel:(NSData *)data
{
    //convert to string
    NSString *string = [[NSString alloc] initWithBytesNoCopy:(void *)data.bytes length:data.length encoding:NSASCIIStringEncoding freeWhenDone:NO];
    
    //set up storage
    NSMutableData *tempVertexData = [[NSMutableData alloc] init];
    NSMutableData *vertexData = [[NSMutableData alloc] init];
    NSMutableData *tempTextCoordData = [[NSMutableData alloc] init];
    NSMutableData *textCoordData = [[NSMutableData alloc] init];
    NSMutableData *tempNormalData = [[NSMutableData alloc] init];
    NSMutableData *normalData = [[NSMutableData alloc] init];
    NSMutableData *faceIndexData = [[NSMutableData alloc] init];
    
    //utility collections
    NSInteger uniqueIndexStrings = 0;
    NSMutableDictionary *indexStrings = [[NSMutableDictionary alloc] init];
    
    //scan through lines
    NSString *line = nil;
    NSScanner *lineScanner = [NSScanner scannerWithString:string];
    
    int SizeGLuint = sizeof(GLuint);
    int SizeGLfloat = sizeof(GLfloat);
    int fcount = 0;
    int vcount = 0;
    
    /*
    NSDate *methodStart = [NSDate date];
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:methodStart];
    NSTimeInterval fETime = executionTime, vEtime = executionTime, vtEtime = executionTime, vnEtime = executionTime;
    
    NSDate *tStart = [NSDate date];
    NSDate *tFinish = [NSDate date];
    NSTimeInterval tTime = [tFinish timeIntervalSinceDate:tStart];
    NSTimeInterval sTime0 = tTime, sTime1 = tTime, sTime2 = tTime, sTime3 = tTime, sTime4 = tTime, sTime5 = tTime, sTime6 = tTime;
    */
    
    NSLog(@"loadobj 3");  // check
    do
    {
        //get line
        [lineScanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&line];
        NSScanner *scanner = [NSScanner scannerWithString:line];
        
        //get line type
        NSString *type = nil;
        [scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&type];
        
        if ([type isEqualToString:@"v"])
        {
            //vertex
            vcount++;
            //methodStart = [NSDate date];
            GLfloat coords[3];
            [scanner scanFloat:&coords[0]];
            [scanner scanFloat:&coords[1]];
            [scanner scanFloat:&coords[2]];
            [tempVertexData appendBytes:coords length:sizeof(coords)];
            //methodFinish = [NSDate date];
            //executionTime = [methodFinish timeIntervalSinceDate:methodStart];
            //vEtime = vEtime + executionTime;

        }
        else if ([type isEqualToString:@"vt"])
        {
            //texture coordinate
            //methodStart = [NSDate date];
            GLfloat coords[2];
            [scanner scanFloat:&coords[0]];
            [scanner scanFloat:&coords[1]];
            [tempTextCoordData appendBytes:coords length:sizeof(coords)];
            //methodFinish = [NSDate date];
            //executionTime = [methodFinish timeIntervalSinceDate:methodStart];
            //vtEtime = vtEtime + executionTime;
        }
        else if ([type isEqualToString:@"vn"])
        {
            //normal
            //methodStart = [NSDate date];
            GLfloat coords[3];
            [scanner scanFloat:&coords[0]];
            [scanner scanFloat:&coords[1]];
            [scanner scanFloat:&coords[2]];
            [tempNormalData appendBytes:coords length:sizeof(coords)];
            //methodFinish = [NSDate date];
            //executionTime = [methodFinish timeIntervalSinceDate:methodStart];
            //vnEtime = vnEtime + executionTime;
        }
        else if ([type isEqualToString:@"f"])
        {
            //face
            fcount ++;
            
            int count = 0;
            
            //methodStart = [NSDate date];
            NSString *indexString = nil;
            
            while (![scanner isAtEnd])  // time-consuming
            {
                count ++;
                [scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&indexString];  // time-consuming
                
                NSArray *parts = [indexString componentsSeparatedByString:@"/"];  // time-consuming
                
                GLuint fIndex = uniqueIndexStrings;
                NSNumber *index = indexStrings[indexString];
                
                
                if (index == nil)
                {
                    //tStart = [NSDate date];
                    uniqueIndexStrings ++;
                    indexStrings[indexString] = @(fIndex);
                    
                    GLuint vIndex = [parts[0] intValue];
                    [vertexData appendBytes: (GLbyte *)tempVertexData.bytes + (vIndex - 1) * SizeGLfloat * 3 length:SizeGLfloat * 3];
                    
                    if ([parts count] > 1)
                    {
                        GLuint tIndex = [parts[1] intValue];
                        if (tIndex) [textCoordData appendBytes: (GLbyte *)tempTextCoordData.bytes + (tIndex - 1) * SizeGLfloat * 2 length:SizeGLfloat * 2];
                    }
                    
                    if ([parts count] > 2)
                    {
                        GLuint nIndex = [parts[2] intValue];
                        if (nIndex) [normalData appendBytes: (GLbyte *)tempNormalData.bytes + (nIndex - 1) * SizeGLfloat * 3 length:SizeGLfloat * 3];
                    }
                    //tFinish = [NSDate date];
                    //tTime = [tFinish timeIntervalSinceDate:tStart];
                    //sTime1 = sTime1 + tTime;
                }
                else
                {
                    //tStart = [NSDate date];
                    fIndex = [index unsignedLongValue];
                    //tFinish = [NSDate date];
                    //tTime = [tFinish timeIntervalSinceDate:tStart];
                    //sTime2 = sTime2 + tTime;
                }
                
                if (count > 3)
                {
                    //face has more than 3 sides
                    //so insert extra triangle coords
                    //tStart = [NSDate date];
                    
                    [faceIndexData appendBytes:(GLbyte *)faceIndexData.bytes + faceIndexData.length - SizeGLuint * 3 length:SizeGLuint];
                    [faceIndexData appendBytes:(GLbyte *)faceIndexData.bytes + faceIndexData.length - SizeGLuint * 2 length:SizeGLuint];
                    //tFinish = [NSDate date];
                    //tTime = [tFinish timeIntervalSinceDate:tStart];
                    //sTime3 = sTime3 + tTime;
                }
                
                //tStart = [NSDate date];
                
                [faceIndexData appendBytes:&fIndex length:SizeGLuint];
                
                //tFinish = [NSDate date];
                //tTime = [tFinish timeIntervalSinceDate:tStart];
                //sTime4 = sTime4 + tTime;
                
                //methodFinish = [NSDate date];
                //executionTime = [methodFinish timeIntervalSinceDate:methodStart];
                //fETime = fETime + executionTime;

            }
            
        }
        //TODO: more
    }
    while (![lineScanner isAtEnd]);
    
    
    NSLog(@"loadobj 4=> face: %d, vertices: %d", fcount, vcount);  // check
    //face: 82390, vertices: 76385
    //NSLog(@"Time=> fETime: %f, vEtime: %f, vtETime: %f, vnEtime: %f", fETime, vEtime, vtEtime, vnEtime);  // check
    //fETime: 23.699393, vEtime: 0.603432, vtETime: 0.481311, vnEtime: 0.604745
    //NSLog(@"subtime=> sTime0: %f, sTime5: %f, sTime6: %f, sTime1: %f, sTime2: %f, sTime3: %f, sTime4: %f", sTime0, sTime5, sTime6, sTime1, sTime2, sTime3, sTime4);
    //sTime0: 1.920398, sTime5: 2.962393, sTime6: 1.017529, sTime1: 0.990950, sTime2: 0.439304, sTime3: 0.000002, sTime4: 0.614738
    
    
    //release temporary storage
    
    //copy elements
    self.elementCount = [faceIndexData length] / sizeof(GLuint);
    GLuint *faceIndices = (GLuint *)faceIndexData.bytes;
    if (self.elementCount > USHRT_MAX)
    {
        self.elementType = GL_UNSIGNED_INT_OES;
        self.elementSize = sizeof(GLuint);
        self.elements = malloc([faceIndexData length]);
        memcpy(self.elements, faceIndices, [faceIndexData length]);
    }
    else if (self.elementCount > UCHAR_MAX)
    {
        self.elementType = GL_UNSIGNED_SHORT;
        self.elementSize = sizeof(GLushort);
        self.elements = malloc([faceIndexData length] / 2);
        for (GLuint i = 0; i < _elementCount; i++)
        {
            ((GLushort *)_elements)[i] = faceIndices[i];
        }
    }
    else
    {
        self.elementType = GL_UNSIGNED_BYTE;
        self.elementSize = sizeof(GLubyte);
        self.elements = malloc([faceIndexData length] / 4);
        for (GLuint i = 0; i < _elementCount; i++)
        {
            ((GLubyte *)_elements)[i] = faceIndices[i];
        }
    }
    
    //copy vertices
    self.componentCount = 3;
    self.vertexCount = [vertexData length] / (3 * sizeof(GLfloat));
    self.vertices = (GLfloat *)malloc([vertexData length]);
    memcpy(self.vertices, vertexData.bytes, [vertexData length]);
    
    /*
    // get center of vertices
    NSLog(@"get center point");
    self.centerpos =(GLfloat *)malloc(3 * sizeof(GLfloat));
    self.centerpos[0] = 0;
    self.centerpos[1] = 0;
    self.centerpos[2] = 0;
    for (GLuint i = 0; i < self.vertexCount; i++)
    {
        self.centerpos[0] = self.centerpos[0]+ self.vertices[3*i];
        self.centerpos[1] = self.centerpos[1]+ self.vertices[3*i+1];
        self.centerpos[2] = self.centerpos[2]+ self.vertices[3*i+2];
    }
    self.centerpos[0] = self.centerpos[0]/self.vertexCount;
    self.centerpos[1] = self.centerpos[1]/self.vertexCount;
    self.centerpos[2] = self.centerpos[2]/self.vertexCount;
    NSLog(@"finish center point: %f, %f, %f", self.centerpos[0],self.centerpos[1],self.centerpos[2]);
    */
    
    //copy texture coords
    if ([textCoordData length])
    {
        self.texCoords = (GLfloat *)malloc([textCoordData length]);
        memcpy(self.texCoords, textCoordData.bytes, [textCoordData length]);
    }
    
    //copy normals
    if ([normalData length])
    {
        self.normals = (GLfloat *)malloc([normalData length]);
        memcpy(self.normals, normalData.bytes, [normalData length]);
    }
    
    
    //success
    return YES;
}
/*
- (float*)centerpoint
{
    return (float*)(self.centerpos);
}
*/

#pragma mark -
#pragma mark Caching

static NSCache *modelCache = nil;

+ (void)initialize
{
    modelCache = [[NSCache alloc] init];
}

+ (GLModel *)modelNamed:(NSString *)nameOrPath
{
    NSString *path = [nameOrPath GL_normalizedPathWithDefaultExtension:@"obj"];
    GLModel *model = nil;
    if (path)
    {
        model = [modelCache objectForKey:path];
        if (!model)
        {
            model = [self modelWithContentsOfFile:nameOrPath];
            if (model)
            {
                [modelCache setObject:model forKey:path];
            }
        }
    }
    return model;
}



#pragma mark -
#pragma mark Loading

+ (instancetype)modelWithContentsOfFile:(NSString *)nameOrPath
{
    return [(GLModel *)[self alloc] initWithContentsOfFile:nameOrPath];
}

+ (instancetype)modelWithData:(NSData *)data
{
    return [(GLModel *)[self alloc] initWithData:data];
}

- (GLModel *)initWithContentsOfFile:(NSString *)nameOrPath
{
    //normalise path
    NSString *path = [nameOrPath GL_normalizedPathWithDefaultExtension:@"obj"];
    
    //load data
    return [self initWithData:[NSData dataWithContentsOfFile:path]];
}

- (GLModel *)initWithData:(NSData *)data
{
    NSLog(@"initWithData  now");
    
    //attempt to unzip data
    data = [data GL_unzippedData];
    
    NSLog(@"check data  now");
    
    if (!data)
    {
        //bail early before something bad happens
        return nil;
    }
    NSLog(@"self init  now");

    if ((self = [self init]))
    {
        NSLog(@"check loadAppleWWDC2010Model data now");
        
        if ([self loadAppleWWDC2010Model:data])
        {
            NSLog(@"loadAppleWWDC2010Model loading now");
            return self;
        }
        else
        {
            NSLog(@"check loadObjModel data now");
            
            if ([self loadObjModel:data])
            {
                NSLog(@"loadObjModel  now");
                return self;
            }
            else
            {
                NSLog(@"Model data was not in a recognised format");
                return nil;
            }
            
        }
        
        /*
        //attempt to load model
        if ([self loadAppleWWDC2010Model:data])
        {
            NSLog(@"loadAppleWWDC2010Model loading now");
            return self;
        }
        else if ([self loadObjModel:data])
        {
            NSLog(@"loadObjModel  now");
            return self;
        }
        else
        {
            NSLog(@"Model data was not in a recognised format");
            return nil;
        }
        */
    }
    return self;
}


#pragma mark -
#pragma mark Drawing

- (void)draw
{
    glEnable(GL_DEPTH_TEST);

    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(self.componentCount, GL_FLOAT, 0, self.vertices);
    
    if (self.texCoords)
    {
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        glTexCoordPointer(2, GL_FLOAT, 0, self.texCoords);
    }
    else
    {
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    }
    
    if (self.normals)
    {
        glEnableClientState(GL_NORMAL_ARRAY);
        glNormalPointer(GL_FLOAT, 0, self.normals);
    }
    else
    {
        glDisableClientState(GL_NORMAL_ARRAY);
    }
    
    glDrawElements(GL_TRIANGLES, self.elementCount, self.elementType, self.elements);
    
    glDisable(GL_DEPTH_TEST);
}

@end
