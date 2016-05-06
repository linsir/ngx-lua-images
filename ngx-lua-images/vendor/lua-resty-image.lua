-- GraphicMagic lua binding --

local string = require("string")
local ffi = require("ffi")
local tonumber = tonumber
local setmetatable = setmetatable

local _M = {}
_M._VERSION = '0.6'
local mt = { __index = _M }

ffi.cdef
[[
typedef void MagickWand;
typedef void DrawingWand;
typedef void PixelWand;
typedef int MagickBooleanType;
typedef int ExceptionType;
typedef int size_t;


typedef enum
{
  UndefinedFilter,
  PointFilter,
  BoxFilter,
  TriangleFilter,
  HermiteFilter,
  HanningFilter,
  HammingFilter,
  BlackmanFilter,
  GaussianFilter,
  QuadraticFilter,
  CubicFilter,
  CatromFilter,
  MitchellFilter,
  LanczosFilter,
  BesselFilter,
  SincFilter
} FilterTypes;


typedef enum
{
  ForgetGravity,
  NorthWestGravity,
  NorthGravity,
  NorthEastGravity,
  WestGravity,
  CenterGravity,
  EastGravity,
  SouthWestGravity,
  SouthGravity,
  SouthEastGravity,
  StaticGravity
} GravityType;


// Init
void InitializeMagick();

// *** Magick Wand ***
MagickWand* NewMagickWand();
MagickWand* DestroyMagickWand( MagickWand * );

// Free resouse
unsigned int MagickRelinquishMemory( void *resource );

// Desc
unsigned char * MagickGetImageFormat( MagickWand *wand );
unsigned char * MagickGetImageProfile( MagickWand *wand, const char *name, unsigned long *length );
unsigned char * MagickDescribeImage( MagickWand *wand );

// Read/Write
MagickBooleanType MagickReadImageBlob( MagickWand*, const void*, const size_t );
unsigned char *MagickWriteImageBlob( MagickWand *wand, size_t *length );
unsigned int MagickWriteImage( MagickWand *wand, const char *filename );
unsigned int MagickReadImage( MagickWand *wand, const char *filename );

// Size
unsigned long MagickGetImageWidth( MagickWand *wand );
unsigned long MagickGetImageHeight( MagickWand *wand );

// Resize
unsigned int MagickResizeImage( MagickWand *wand, const unsigned long columns,
                                const unsigned long rows, const FilterTypes filter,
                                const double blur );

// Quality
unsigned int MagickSetCompressionQuality( MagickWand *wand, const unsigned long quality );

// Remove profile
unsigned int MagickStripImage( MagickWand *wand );

// Annote Text
unsigned int MagickAnnotateImage( MagickWand *wand, const DrawingWand *drawing_wand,
                                  const double x, const double y, const double angle,
                                  const char *text );

// Rotate
unsigned int MagickRotateImage( MagickWand *wand, const PixelWand *background,
                                const double degrees );
unsigned int MagickFlipImage( MagickWand *wand );
unsigned int MagickFlopImage( MagickWand *wand );

// *** Drawing Wand ***
DrawingWand *MagickNewDrawingWand();
void MagickDestroyDrawingWand( DrawingWand *drawing_wand );

// Set text encoding
void MagickDrawSetTextEncoding( DrawingWand *drawing_wand, const char *encoding );

// Font
void MagickDrawSetFont( DrawingWand *drawing_wand, const char *font_name );
void MagickDrawSetFontSize( DrawingWand *drawing_wand, const double pointsize );
void MagickDrawSetFillColor( DrawingWand *drawing_wand, const PixelWand *fill_wand );
void MagickDrawSetGravity( DrawingWand *drawing_wand, const GravityType gravity );

// *** Pixel Wand ***
PixelWand* NewPixelWand();
unsigned int DestroyPixelWand( PixelWand *wand );

// Set color
unsigned int PixelSetColor( PixelWand *wand, const char *color );

// Set image format
unsigned int MagickSetImageFormat( MagickWand *wand, const char *format );


// System function for mkdir
int mkdir( const char *path, int mode );

]]


local libgm = ffi.load('libGraphicsMagickWand')
libgm.InitializeMagick()

local function magick_wand()
  return libgm.NewMagickWand()
end

local function destroy_magick_wand(wand)
  libgm.DestroyMagickWand(ffi.gc(wand, nil))
end

local function pixel_wand()
	local pwand = ffi.gc(libgm.NewPixelWand(), libgm.DestroyPixelWand)
	return pwand
end

local function destroy_pixel_wand(pwand)
  libgm.DestroyPixelWand(ffi.gc(pwand, nil))
end

local function draw_wand()
	local dwand = ffi.gc(libgm.MagickNewDrawingWand(), libgm.MagickDestroyDrawingWand)
	return dwand
end

local function destroy_draw_wand(dwand)
  libgm.DestroyMagickWand(ffi.gc(dwand, nil))
end

local function set_gravity(dwand, gravity)
	local g = libgm[gravity .. 'Gravity']
	if not g then
		return 0
	end
  return libgm.MagickDrawSetGravity(dwand, g)
end

local function set_font(dwand, path, size, color)
	if libgm.MagickDrawSetFont(dwand, path) == 0 then
		return 0
	end

	if libgm.MagickDrawSetFontSize(dwand, size) == 0 then
		return 0
	end

	local pwand = pixel_wand()
  if not pwand then
    return 0
  end

	if libgm.PixelSetColor(pwand, color) == 0 then
    destroy_pixel_wand(pwand)
		return 0
	end

  destroy_pixel_wand(pwand)
	return libgm.MagickDrawSetFillColor(dwand, pwand)
end

local function orientation(s)
	local o = string.match(s, 'Orientation:%s*(%d)')
	if o then
		local n = tonumber(o)
		if 0 < n and n < 9 then
			return n
		end
	end
	return 0
end



------------------module functions----------------------

function _M.new(self, img, t)
	local mwand = ffi.gc(libgm.NewMagickWand(), libgm.DestroyMagickWand)

  if not mwand then
    return nil
  end

	local r = 0
	if t == 'mem' then
		r = libgm.MagickReadImageBlob(mwand, img, #img)
	elseif t == 'file' then
		r = libgm.MagickReadImage(mwand, img)
	end

  if r == 0 then
    destroy_magick_wand(mwand)
    return nil
  end

  return setmetatable({_mwand = mwand}, mt)
end

function _M.width(self)
	return libgm.MagickGetImageWidth(self._mwand)
end

function _M.height(self)
	return libgm.MagickGetImageHeight(self._mwand)
end

function _M.profile(self, name)
	local len = ffi.new('size_t[1]', 0)
	local blob = libgm.MagickGetImageProfile(self._mwand, name, len)
	if ffi.cast('void *', blob) > nil then
		local s = ffi.string(blob, len[0])
		libgm.MagickRelinquishMemory(blob)
		return s
	else
		return nil
	end
end

function _M.desc(self)
	local blob = libgm.MagickDescribeImage(self._mwand)
	if ffi.cast('void *', blob) > nil then
		local s = ffi.string(blob)
		libgm.MagickRelinquishMemory(blob)
		return s
	else
		return nil
	end
end

function _M.rotate(self, degree)
	local pwand = pixel_wand()
	if not pwand then
		return 0
	end
	local r = libgm.MagickRotateImage(self._mwand, pwand, degree)
  destroy_pixel_wand(pwand)
  return r
end

function _M.flip(self)
	return libgm.MagickFlipImage(self._mwand)
end

function _M.flop(self)
	return libgm.MagickFlopImage(self._mwand)
end

function _M.jpeg_rm_orientation(self)
	local desc = self:desc()
	if not desc then
		return
	end
	local o = orientation(desc)
	if     o == 1 then
	elseif o == 2 then
		self:flop()
	elseif o == 3 then
		self:rotate(180)
	elseif o == 4 then
		self:flip()
	elseif o == 5 then
		self:rotate(90)
		self:flop()
	elseif o == 6 then
		self:rotate(90)
	elseif o == 7 then
		self:rotate(-90)
		self:flop()
	elseif o == 8 then
		self:rotate(-90)
	end
end

function _M.resize(self, w, h)
	if not h or h == 0 then
		h = w * self:height() / self:width()
	end

	if not w or w == 0 then
		w = h * self:width() / self:height()
	end

	local filter = libgm['LanczosFilter']
	return libgm.MagickResizeImage(self._mwand, w, h, filter, 1.0)
end

function _M.compress(self, quality)
	return libgm.MagickSetCompressionQuality(self._mwand, quality)
end

function _M.strip(self)
	return libgm.MagickStripImage(self._mwand)
end

function _M.format(self, t)
  return libgm.MagickSetImageFormat(self._mwand, t)
end

function _M.string(self)
	local len = ffi.new('size_t[1]', 0)
	local blob = libgm.MagickWriteImageBlob(self._mwand, len)
	if ffi.cast('void *', blob) > nil then
		local s = ffi.string(blob, len[0])
		libgm.MagickRelinquishMemory(blob)
		return s
	else
		return nil
	end
end

function _M.save(self, path)
	return libgm.MagickWriteImage(self._mwand, path)
end

function _M.annote(self, path, size, color, pos, text)
	local i, _ = string.find(pos, ':')
	local gravity = string.sub(pos, 0, i-1)
	local j, _ = string.find(pos, 'x', i+1)
	local x = tonumber(string.sub(pos, i+1, j-1))
	local y = tonumber(string.sub(pos, j+1))

	if not x or not y then
		return 0
	end

	local dwand = draw_wand()
	if not dwand then
		return 0
	end

	libgm.MagickDrawSetTextEncoding(dwand, 'utf-8')

	if set_font(dwand, path, size, color) == 0 then
		return 0
	end

	if set_gravity(dwand, gravity) == 0 then
		return 0
	end

	local r = libgm.MagickAnnotateImage(self._mwand, dwand, x, y, 0, text)
  destroy_draw_wand(dwand)
  return r
end

function _M.destroy(self)
  if self._mwand then
    destroy_magick_wand(self._mwand)
    self._mwand = nil
  end
end

return _M
