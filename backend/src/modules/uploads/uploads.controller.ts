import { Controller, Post, UploadedFile, UseGuards, UseInterceptors } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import multer from 'multer';

import { JwtAuthGuard } from 'src/common/guards/jwt-auth.guard';
import { UploadsService } from './uploads.service';

@Controller('uploads')
@UseGuards(JwtAuthGuard)
export class UploadsController {
  constructor(private readonly uploadsService: UploadsService) {}

  @Post('profile-image')
  @UseInterceptors(FileInterceptor('file', { storage: multer.memoryStorage() }))
  uploadProfileImage(@UploadedFile() file: Express.Multer.File) {
    return this.uploadsService.uploadProfileImage(file);
  }
}
