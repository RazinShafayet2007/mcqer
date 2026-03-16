import { IsArray, IsIn, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class CreateExamDto {
  @IsString()
  title!: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsNumber()
  @Min(1)
  durationMinutes!: number;

  @IsNumber()
  negativeMarkPerWrong!: number;

  @IsIn(['PUBLIC', 'ALL_FRIENDS', 'SELECTED_FRIENDS'])
  visibility!: 'PUBLIC' | 'ALL_FRIENDS' | 'SELECTED_FRIENDS';

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  assignedExamineeIds?: string[];
}
