import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class StorageService {
  private readonly bucket: string;
  private readonly client: SupabaseClient;

  constructor(configService: ConfigService) {
    this.bucket = configService.getOrThrow<string>('SUPABASE_STORAGE_BUCKET');
    this.client = createClient(
      configService.getOrThrow<string>('SUPABASE_URL'),
      configService.getOrThrow<string>('SUPABASE_SERVICE_ROLE_KEY'),
      {
        auth: { persistSession: false, autoRefreshToken: false },
      },
    );
  }

  async uploadProfileImage(key: string, body: Buffer, contentType: string): Promise<{ key: string; url: string }> {
    const { error } = await this.client.storage.from(this.bucket).upload(key, body, {
      contentType,
      upsert: true,
    });
    if (error) {
      throw error;
    }

    const { data } = this.client.storage.from(this.bucket).getPublicUrl(key);

    return {
      key,
      url: data.publicUrl,
    };
  }
}
