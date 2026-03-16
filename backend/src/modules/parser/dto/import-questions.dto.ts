import { IsString } from 'class-validator';

export class ImportQuestionsDto {
  @IsString()
  rawText!: string;
}
