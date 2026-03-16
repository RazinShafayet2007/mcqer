import { IsEmail, IsIn, IsString, MinLength } from 'class-validator';

export class RegisterDto {
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(8)
  password!: string;

  @IsIn(['EXAMINER', 'EXAMINEE'])
  role!: 'EXAMINER' | 'EXAMINEE';

  @IsString()
  name!: string;

  @IsString()
  username!: string;
}
