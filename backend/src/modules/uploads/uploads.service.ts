import { Injectable } from '@nestjs/common';

import { StorageService } from 'src/infra/storage/storage.service';

@Injectable()
export class UploadsService {
  constructor(private readonly storageService: StorageService) {}

  async uploadProfileImage(file: Express.Multer.File) {
    return this.storageService.uploadProfileImage(
      `profiles/${Date.now()}-${file.originalname}`,
      file.buffer,
      file.mimetype,
    );
  }
}
