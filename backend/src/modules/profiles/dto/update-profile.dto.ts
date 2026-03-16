import { IsOptional, IsString } from 'class-validator';

export class UpdateProfileDto {
  @IsString()
  name!: string;

  @IsString()
  username!: string;

  @IsOptional()
  @IsString()
  bio?: string;

  @IsOptional()
  @IsString()
  headline?: string;

  @IsOptional()
  @IsString()
  profileImageUrl?: string | null;
}
